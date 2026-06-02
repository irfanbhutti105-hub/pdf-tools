import os
import uuid
import zipfile
import shutil
import asyncio
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, UploadFile, File, Form, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from PyPDF2 import PdfMerger, PdfReader, PdfWriter

app = FastAPI(title="PDF Tools API", version="1.0.0")

# CORS - allow all origins for Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

TEMP_DIR = Path("temp_files")

@app.on_event("startup")
async def startup_event():
    TEMP_DIR.mkdir(exist_ok=True)

def get_temp_path(suffix: str = ".pdf") -> Path:
    return TEMP_DIR / f"{uuid.uuid4()}{suffix}"

async def save_upload(file: UploadFile) -> Path:
    ext = Path(file.filename).suffix or ".pdf"
    path = get_temp_path(suffix=ext)
    with open(path, "wb") as f:
        f.write(await file.read())
    return path

def cleanup_files(*paths: Path):
    for p in paths:
        try:
            if p and p.exists():
                if p.is_dir():
                    shutil.rmtree(p)
                else:
                    p.unlink()
        except Exception:
            pass

async def schedule_cleanup(*paths: Path, delay: int = 3600):
    """Delete files after `delay` seconds (default 1 hour)."""
    await asyncio.sleep(delay)
    cleanup_files(*paths)

# ─────────────────────────────────────────────
#  ROOT
# ─────────────────────────────────────────────
@app.get("/")
def root():
    return {"message": "PDF Tools API is running.", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "ok"}

# ─────────────────────────────────────────────
#  1. MERGE PDF
# ─────────────────────────────────────────────
@app.post("/api/pdf/merge")
async def merge_pdf(
    background_tasks: BackgroundTasks,
    files: list[UploadFile] = File(...),
):
    if len(files) < 2:
        raise HTTPException(status_code=400, detail="At least 2 PDF files are required.")

    merger = PdfMerger()
    saved_inputs: list[Path] = []
    output_path: Optional[Path] = None

    try:
        for file in files:
            p = await save_upload(file)
            saved_inputs.append(p)
            merger.append(str(p))

        output_path = get_temp_path(".pdf")
        merger.write(str(output_path))
        merger.close()

        background_tasks.add_task(cleanup_files, *saved_inputs, output_path)
        return FileResponse(
            path=str(output_path),
            filename="merged.pdf",
            media_type="application/pdf",
        )
    except Exception as e:
        cleanup_files(*saved_inputs)
        if output_path:
            cleanup_files(output_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  2. SPLIT PDF
# ─────────────────────────────────────────────
@app.post("/api/pdf/split")
async def split_pdf(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    ranges: Optional[str] = Form(None),
    every_page: bool = Form(False),
):
    """
    Split a PDF.
    - `every_page=true`  → each page becomes its own PDF, returned as a ZIP.
    - `ranges`           → comma-separated page ranges like "1-3,5,7-9" (1-indexed), returned as a ZIP.
    """
    input_path = await save_upload(file)
    try:
        reader = PdfReader(str(input_path))
        total = len(reader.pages)

        zip_path = get_temp_path(".zip")
        zip_dir = TEMP_DIR / str(uuid.uuid4())
        zip_dir.mkdir()

        if every_page:
            for i in range(total):
                writer = PdfWriter()
                writer.add_page(reader.pages[i])
                out = zip_dir / f"page_{i + 1}.pdf"
                with open(out, "wb") as f:
                    writer.write(f)
        elif ranges:
            for seg in ranges.split(","):
                seg = seg.strip()
                if "-" in seg:
                    start, end = seg.split("-")
                    start, end = int(start) - 1, int(end) - 1
                else:
                    start = end = int(seg) - 1
                writer = PdfWriter()
                for i in range(start, min(end + 1, total)):
                    writer.add_page(reader.pages[i])
                label = f"pages_{start + 1}_to_{end + 1}.pdf"
                out = zip_dir / label
                with open(out, "wb") as f:
                    writer.write(f)
        else:
            raise HTTPException(status_code=400, detail="Provide 'ranges' or set 'every_page=true'.")

        # Zip the output directory
        with zipfile.ZipFile(zip_path, "w") as z:
            for pdf in zip_dir.glob("*.pdf"):
                z.write(pdf, pdf.name)

        background_tasks.add_task(cleanup_files, input_path, zip_path, zip_dir)
        return FileResponse(
            path=str(zip_path),
            filename="split_pages.zip",
            media_type="application/zip",
        )
    except HTTPException:
        raise
    except Exception as e:
        cleanup_files(input_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  3. COMPRESS PDF
# ─────────────────────────────────────────────
@app.post("/api/pdf/compress")
async def compress_pdf(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    level: str = Form("medium"),  # low | medium | high
):
    """
    Compress a PDF by removing redundant/unused objects.
    True advanced compression requires Ghostscript (optional enhancement).
    """
    input_path = await save_upload(file)
    output_path = get_temp_path(".pdf")
    original_size = input_path.stat().st_size

    try:
        reader = PdfReader(str(input_path))
        writer = PdfWriter()

        for page in reader.pages:
            page.compress_content_streams()
            writer.add_page(page)

        try:
            writer.compress_identical_objects(remove_identicals=True, remove_orphans=True)
        except Exception as e:
            # PyPDF2's compress_identical_objects can sometimes crash on complex or malformed PDFs.
            # We catch it here so that compress_content_streams is still applied.
            print(f"Warning: compress_identical_objects failed: {e}")

        with open(output_path, "wb") as f:
            writer.write(f)

        compressed_size = output_path.stat().st_size
        saved = original_size - compressed_size
        pct = round((saved / original_size) * 100, 1) if original_size > 0 else 0

        background_tasks.add_task(cleanup_files, input_path, output_path)
        return FileResponse(
            path=str(output_path),
            filename="compressed.pdf",
            media_type="application/pdf",
            headers={
                "X-Original-Size": str(original_size),
                "X-Compressed-Size": str(compressed_size),
                "X-Saved-Bytes": str(saved),
                "X-Saved-Percent": str(pct),
            },
        )
    except Exception as e:
        cleanup_files(input_path, output_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  4. ROTATE PDF
# ─────────────────────────────────────────────
@app.post("/api/pdf/rotate")
async def rotate_pdf(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    angle: int = Form(90),
    pages: Optional[str] = Form(None),
):
    """
    Rotate pages by `angle` degrees (90, 180, 270).
    `pages` is a comma-separated list of 1-indexed page numbers. If omitted, all pages are rotated.
    """
    input_path = await save_upload(file)
    output_path = get_temp_path(".pdf")
    try:
        reader = PdfReader(str(input_path))
        writer = PdfWriter()
        total = len(reader.pages)

        if pages:
            target = set(int(p.strip()) - 1 for p in pages.split(","))
        else:
            target = set(range(total))

        for i, page in enumerate(reader.pages):
            if i in target:
                page.rotate(angle)
            writer.add_page(page)

        with open(output_path, "wb") as f:
            writer.write(f)

        background_tasks.add_task(cleanup_files, input_path, output_path)
        return FileResponse(
            path=str(output_path),
            filename="rotated.pdf",
            media_type="application/pdf",
        )
    except Exception as e:
        cleanup_files(input_path, output_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  5. ADD WATERMARK (Text)
# ─────────────────────────────────────────────
@app.post("/api/pdf/watermark")
async def watermark_pdf(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    watermark_text: str = Form("CONFIDENTIAL"),
    opacity: float = Form(0.3),
):
    """
    Overlay a text watermark PDF onto each page.
    Generates the watermark page on-the-fly using reportlab (if available) or PyPDF2.
    """
    input_path = await save_upload(file)
    output_path = get_temp_path(".pdf")
    watermark_path = get_temp_path(".pdf")

    try:
        # Create watermark PDF with reportlab
        try:
            from reportlab.pdfgen import canvas
            from reportlab.lib.pagesizes import A4
            import math

            c = canvas.Canvas(str(watermark_path), pagesize=A4)
            w, h = A4
            c.setFillColorRGB(0.5, 0.5, 0.5, alpha=opacity)
            c.setFont("Helvetica-Bold", 60)
            c.saveState()
            c.translate(w / 2, h / 2)
            c.rotate(45)
            c.drawCentredString(0, 0, watermark_text)
            c.restoreState()
            c.save()
        except ImportError:
            # Fallback: copy the file without watermark
            shutil.copy(input_path, output_path)
            background_tasks.add_task(cleanup_files, input_path, output_path, watermark_path)
            return FileResponse(
                path=str(output_path),
                filename="watermarked.pdf",
                media_type="application/pdf",
                headers={"X-Warning": "reportlab not installed; watermark skipped"},
            )

        reader = PdfReader(str(input_path))
        wm_reader = PdfReader(str(watermark_path))
        writer = PdfWriter()

        wm_page = wm_reader.pages[0]
        for page in reader.pages:
            page.merge_page(wm_page)
            writer.add_page(page)

        with open(output_path, "wb") as f:
            writer.write(f)

        background_tasks.add_task(cleanup_files, input_path, output_path, watermark_path)
        return FileResponse(
            path=str(output_path),
            filename="watermarked.pdf",
            media_type="application/pdf",
        )
    except Exception as e:
        cleanup_files(input_path, output_path, watermark_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  6. PROTECT PDF (Password)
# ─────────────────────────────────────────────
@app.post("/api/pdf/protect")
async def protect_pdf(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    password: str = Form(...),
):
    input_path = await save_upload(file)
    output_path = get_temp_path(".pdf")
    try:
        reader = PdfReader(str(input_path))
        writer = PdfWriter()
        for page in reader.pages:
            writer.add_page(page)
        writer.encrypt(password)

        with open(output_path, "wb") as f:
            writer.write(f)

        background_tasks.add_task(cleanup_files, input_path, output_path)
        return FileResponse(
            path=str(output_path),
            filename="protected.pdf",
            media_type="application/pdf",
        )
    except Exception as e:
        cleanup_files(input_path, output_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  7. UNLOCK PDF
# ─────────────────────────────────────────────
@app.post("/api/pdf/unlock")
async def unlock_pdf(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    password: str = Form(...),
):
    input_path = await save_upload(file)
    output_path = get_temp_path(".pdf")
    try:
        reader = PdfReader(str(input_path))
        if reader.is_encrypted:
            result = reader.decrypt(password)
            if result == 0:
                cleanup_files(input_path)
                raise HTTPException(status_code=401, detail="Incorrect password.")

        writer = PdfWriter()
        for page in reader.pages:
            writer.add_page(page)

        with open(output_path, "wb") as f:
            writer.write(f)

        background_tasks.add_task(cleanup_files, input_path, output_path)
        return FileResponse(
            path=str(output_path),
            filename="unlocked.pdf",
            media_type="application/pdf",
        )
    except HTTPException:
        raise
    except Exception as e:
        cleanup_files(input_path, output_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  8. IMAGES TO PDF
# ─────────────────────────────────────────────
@app.post("/api/pdf/images-to-pdf")
async def images_to_pdf(
    background_tasks: BackgroundTasks,
    files: list[UploadFile] = File(...),
    orientation: str = Form("portrait"),
    margin: int = Form(20),
):
    """Convert image files (JPG, PNG, etc.) to a single PDF."""
    try:
        from PIL import Image
        from reportlab.pdfgen import canvas
        from reportlab.lib.pagesizes import A4, landscape
    except ImportError:
        raise HTTPException(
            status_code=500,
            detail="Pillow and reportlab are required for image conversion. Run: pip install Pillow reportlab",
        )

    output_path = get_temp_path(".pdf")
    saved_inputs: list[Path] = []

    try:
        pagesize = landscape(A4) if orientation == "landscape" else A4
        pw, ph = pagesize

        c = canvas.Canvas(str(output_path), pagesize=pagesize)
        for file in files:
            p = await save_upload(file)
            saved_inputs.append(p)
            img = Image.open(str(p))
            iw, ih = img.size
            avail_w = pw - 2 * margin
            avail_h = ph - 2 * margin
            scale = min(avail_w / iw, avail_h / ih)
            draw_w, draw_h = iw * scale, ih * scale
            x = (pw - draw_w) / 2
            y = (ph - draw_h) / 2
            c.drawImage(str(p), x, y, draw_w, draw_h)
            c.showPage()

        c.save()

        background_tasks.add_task(cleanup_files, *saved_inputs, output_path)
        return FileResponse(
            path=str(output_path),
            filename="images_to_pdf.pdf",
            media_type="application/pdf",
        )
    except HTTPException:
        raise
    except Exception as e:
        cleanup_files(*saved_inputs, output_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  9. PDF TO IMAGES
# ─────────────────────────────────────────────
@app.post("/api/pdf/pdf-to-images")
async def pdf_to_images(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    dpi: int = Form(150),
):
    """Convert each page of a PDF to a JPG image, returned as ZIP."""
    try:
        from pdf2image import convert_from_path
    except ImportError:
        raise HTTPException(
            status_code=500,
            detail="pdf2image is required. Run: pip install pdf2image (also needs Poppler installed).",
        )

    input_path = await save_upload(file)
    zip_path = get_temp_path(".zip")
    img_dir = TEMP_DIR / str(uuid.uuid4())
    img_dir.mkdir()

    try:
        images = convert_from_path(str(input_path), dpi=dpi)
        img_paths: list[Path] = []
        for i, img in enumerate(images):
            img_path = img_dir / f"page_{i + 1}.jpg"
            img.save(str(img_path), "JPEG", quality=90)
            img_paths.append(img_path)

        with zipfile.ZipFile(zip_path, "w") as z:
            for p in img_paths:
                z.write(p, p.name)

        background_tasks.add_task(cleanup_files, input_path, zip_path, img_dir)
        return FileResponse(
            path=str(zip_path),
            filename="pdf_pages.zip",
            media_type="application/zip",
        )
    except Exception as e:
        cleanup_files(input_path, img_dir)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  10. PDF INFO
# ─────────────────────────────────────────────
@app.post("/api/pdf/info")
async def pdf_info(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
):
    """Return metadata about a PDF: page count, title, author, etc."""
    input_path = await save_upload(file)
    try:
        reader = PdfReader(str(input_path))
        meta = reader.metadata or {}
        info = {
            "page_count": len(reader.pages),
            "title": meta.get("/Title", ""),
            "author": meta.get("/Author", ""),
            "subject": meta.get("/Subject", ""),
            "creator": meta.get("/Creator", ""),
            "is_encrypted": reader.is_encrypted,
            "file_size_bytes": input_path.stat().st_size,
        }
        background_tasks.add_task(cleanup_files, input_path)
        return JSONResponse(content=info)
    except Exception as e:
        cleanup_files(input_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  11. EXTRACT TEXT (OCR-ready)
# ─────────────────────────────────────────────
@app.post("/api/pdf/extract-text")
async def extract_text(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
):
    input_path = await save_upload(file)
    try:
        reader = PdfReader(str(input_path))
        pages_text = []
        for i, page in enumerate(reader.pages):
            pages_text.append({"page": i + 1, "text": page.extract_text() or ""})
        background_tasks.add_task(cleanup_files, input_path)
        return JSONResponse(content={"pages": pages_text, "total_pages": len(reader.pages)})
    except Exception as e:
        cleanup_files(input_path)
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  12. TEXT TO PDF
# ─────────────────────────────────────────────
@app.post("/api/pdf/text-to-pdf")
async def text_to_pdf(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
):
    """Convert a plain text/HTML file to a PDF."""
    try:
        from xhtml2pdf import pisa
    except ImportError:
        raise HTTPException(
            status_code=500,
            detail="xhtml2pdf is required. Run: pip install xhtml2pdf",
        )

    input_path = await save_upload(file)
    output_path = get_temp_path(".pdf")

    try:
        with open(input_path, "r", encoding="utf-8", errors="replace") as f:
            text = f.read()

        # Wrap plain text in simple HTML if it doesn't look like HTML
        if "<html" not in text.lower() and "<p" not in text.lower() and "<div" not in text.lower():
            text = f"<html><body><pre>{text}</pre></body></html>"
            
        with open(output_path, "wb") as result_file:
            pisa_status = pisa.CreatePDF(text, dest=result_file)

        if pisa_status.err:
            raise Exception("Failed to generate PDF from text/HTML")

        background_tasks.add_task(cleanup_files, input_path, output_path)
        return FileResponse(
            path=str(output_path),
            filename="text_to_pdf.pdf",
            media_type="application/pdf",
        )
    except HTTPException:
        raise
    except Exception as e:
        cleanup_files(input_path, output_path)
        raise HTTPException(status_code=500, detail=str(e))
