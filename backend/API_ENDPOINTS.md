# PDF Tools API - Available Endpoints

## Base URLs
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs (Interactive Swagger UI)
- **Alternative Docs**: http://localhost:8000/redoc

---

## ✅ Currently Implemented Endpoints

### 1. **Merge PDF**
- **POST** `/api/pdf/merge`
- Combine multiple PDFs in the order you want
- **Parameters**: `files` (multiple PDF files)

### 2. **Split PDF**
- **POST** `/api/pdf/split`
- Separate pages into independent PDF files
- **Parameters**: 
  - `file` (PDF file)
  - `ranges` (comma-separated page ranges like "1-3,5,7-9")
  - `every_page` (boolean - split every page)

### 3. **Compress PDF**
- **POST** `/api/pdf/compress`
- Reduce file size while optimizing quality
- **Parameters**: 
  - `file` (PDF file)
  - `level` (low/medium/high)

### 4. **Rotate PDF**
- **POST** `/api/pdf/rotate`
- Rotate pages by specified degrees
- **Parameters**: 
  - `file` (PDF file)
  - `angle` (90, 180, 270)
  - `pages` (comma-separated page numbers, optional)

### 5. **Watermark**
- **POST** `/api/pdf/watermark`
- Stamp text over your PDF
- **Parameters**: 
  - `file` (PDF file)
  - `watermark_text` (text to overlay)
  - `opacity` (0.0 to 1.0)

### 6. **Protect PDF**
- **POST** `/api/pdf/protect`
- Add password protection
- **Parameters**: 
  - `file` (PDF file)
  - `password` (password string)

### 7. **Unlock PDF**
- **POST** `/api/pdf/unlock`
- Remove password security
- **Parameters**: 
  - `file` (PDF file)
  - `password` (password string)

### 8. **JPG to PDF**
- **POST** `/api/pdf/images-to-pdf`
- Convert JPG/PNG images to PDF
- **Parameters**: 
  - `files` (multiple image files)
  - `orientation` (portrait/landscape)
  - `margin` (margin in pixels)

### 9. **PDF to JPG**
- **POST** `/api/pdf/pdf-to-images`
- Convert each PDF page into JPG
- **Parameters**: 
  - `file` (PDF file)
  - `dpi` (resolution, default 150)

### 10. **Extract Text**
- **POST** `/api/pdf/extract-text`
- Extract text from PDF pages
- **Parameters**: `file` (PDF file)

### 11. **Text to PDF**
- **POST** `/api/pdf/text-to-pdf`
- Convert plain text/HTML/Excel to PDF
- **Parameters**: `file` (text/HTML/XLSX file)

### 12. **PDF Info**
- **POST** `/api/pdf/info`
- Get metadata about a PDF (page count, title, author, etc.)
- **Parameters**: `file` (PDF file)

---

## 🆕 Newly Added Endpoints

### 13. **Word to PDF**
- **POST** `/api/pdf/word-to-pdf`
- Make DOCX files easy to read by converting to PDF
- **Parameters**: `file` (DOCX/DOC file)

### 14. **PDF to Word**
- **POST** `/api/pdf/pdf-to-word`
- Convert PDF to editable DOCX document
- **Parameters**: `file` (PDF file)

### 15. **PDF to Excel**
- **POST** `/api/pdf/pdf-to-excel`
- Pull data from PDFs into Excel spreadsheets
- **Parameters**: `file` (PDF file)
- **Note**: Requires Java installed for tabula-py

### 16. **Excel to PDF**
- **POST** `/api/pdf/excel-to-pdf`
- Make Excel spreadsheets easy to read by converting to PDF
- **Parameters**: `file` (XLSX/XLS file)

### 17. **PowerPoint to PDF**
- **POST** `/api/pdf/powerpoint-to-pdf`
- Make PPT slideshows easy to view as PDF
- **Parameters**: `file` (PPTX/PPT file)

### 18. **PDF to PowerPoint**
- **POST** `/api/pdf/pdf-to-powerpoint`
- Turn PDF files into editable PPTX slideshows
- **Parameters**: `file` (PDF file)

### 19. **HTML to PDF (URL)**
- **POST** `/api/pdf/html-url-to-pdf`
- Convert webpages to PDF
- **Parameters**: `url` (webpage URL)

### 20. **Organize PDF**
- **POST** `/api/pdf/organize`
- Sort/reorder pages of your PDF
- **Parameters**: 
  - `file` (PDF file)
  - `page_order` (comma-separated page numbers like "3,1,2,5")

### 21. **Add Page Numbers**
- **POST** `/api/pdf/add-page-numbers`
- Add page numbers to PDF
- **Parameters**: 
  - `file` (PDF file)
  - `position` (bottom-center/top-center/bottom-right/etc.)
  - `start_number` (starting page number)

### 22. **OCR PDF**
- **POST** `/api/pdf/ocr`
- Make scanned PDFs searchable and selectable
- **Parameters**: 
  - `file` (PDF file)
  - `language` (default: "eng")
- **Note**: Requires Tesseract OCR installed

### 23. **Crop PDF**
- **POST** `/api/pdf/crop`
- Crop margins from PDF pages
- **Parameters**: 
  - `file` (PDF file)
  - `left`, `right`, `top`, `bottom` (crop amounts in points)

### 24. **Redact PDF**
- **POST** `/api/pdf/redact`
- Permanently remove sensitive information
- **Parameters**: 
  - `file` (PDF file)
  - `search_terms` (comma-separated terms to redact)

---

## 📝 Tools Still Missing (Future Implementation)

The following tools from your list still need implementation:

1. **Edit PDF** - Add text, images, shapes or freehand annotations
2. **Sign PDF** - Digital signatures and e-signatures
3. **PDF to PDF/A** - Convert to ISO-standardized archival format
4. **Repair PDF** - Fix damaged/corrupt PDFs
5. **Scan to PDF** - Mobile device scanning (frontend feature)
6. **Compare PDF** - Side-by-side document comparison

---

## 🔧 System Requirements

### Required for all features:
- Python 3.12+
- All packages in requirements.txt

### Optional (for specific features):
- **Java Runtime** - Required for PDF to Excel (tabula-py)
- **Tesseract OCR** - Required for OCR PDF
  - Download from: https://github.com/UB-Mannheim/tesseract/wiki
- **Poppler** - Required for PDF to images
  - Download from: https://github.com/oschwartz10612/poppler-windows/releases

---

## 📊 Testing the API

1. **Interactive Documentation**: Visit http://localhost:8000/docs
2. **Health Check**: GET http://localhost:8000/health
3. **Version Info**: GET http://localhost:8000/

All endpoints return files directly or JSON responses with appropriate headers.

---

## 🎯 Total Implemented Tools

**24 out of 30** requested tools are now implemented and ready to use!
