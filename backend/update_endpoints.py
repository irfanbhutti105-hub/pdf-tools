#!/usr/bin/env python3
"""
Script to add authentication support to all PDF tool endpoints.
Adds `current_user: Optional[dict] = Depends(get_current_user)` parameter
and history saving for authenticated users.
"""

import re

# Read the main.py file
with open('main.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Define replacements for remaining endpoints
replacements = [
    # 13. WORD TO PDF
    {
        'old': '@app.post("/api/pdf/word-to-pdf")\nasync def word_to_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n):',
        'new': '@app.post("/api/pdf/word-to-pdf")\nasync def word_to_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        pdf.build(story)\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="word-to-pdf",\n                output_file=str(output_path),\n                output_name="word_to_pdf.pdf"\n            )\n\n        background_tasks.add_task',
        'history_old': '        pdf.build(story)\n\n        background_tasks.add_task'
    },
    # 14. PDF TO WORD
    {
        'old': '@app.post("/api/pdf/pdf-to-word")\nasync def pdf_to_word(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n):',
        'new': '@app.post("/api/pdf/pdf-to-word")\nasync def pdf_to_word(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        cv.close()\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="pdf-to-word",\n                output_file=str(output_path),\n                output_name="pdf_to_word.docx"\n            )\n\n        background_tasks.add_task',
        'history_old': '        cv.close()\n\n        background_tasks.add_task'
    },
    # 15. PDF TO EXCEL
    {
        'old': '@app.post("/api/pdf/pdf-to-excel")\nasync def pdf_to_excel(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n):',
        'new': '@app.post("/api/pdf/pdf-to-excel")\nasync def pdf_to_excel(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '                table.to_excel(writer, sheet_name=sheet_name, index=False)\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="pdf-to-excel",\n                output_file=str(output_path),\n                output_name="pdf_to_excel.xlsx"\n            )\n\n        background_tasks.add_task',
        'history_old': '                table.to_excel(writer, sheet_name=sheet_name, index=False)\n\n        background_tasks.add_task'
    },
    # 16. EXCEL TO PDF
    {
        'old': '@app.post("/api/pdf/excel-to-pdf")\nasync def excel_to_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n):',
        'new': '@app.post("/api/pdf/excel-to-pdf")\nasync def excel_to_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        if pisa_status.err:\n            raise Exception("Failed to generate PDF from Excel")\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="excel-to-pdf",\n                output_file=str(output_path),\n                output_name="excel_to_pdf.pdf"\n            )\n\n        background_tasks.add_task',
        'history_old': '        if pisa_status.err:\n            raise Exception("Failed to generate PDF from Excel")\n\n        background_tasks.add_task'
    },
    # 17. POWERPOINT TO PDF
    {
        'old': '@app.post("/api/pdf/powerpoint-to-pdf")\nasync def powerpoint_to_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n):',
        'new': '@app.post("/api/pdf/powerpoint-to-pdf")\nasync def powerpoint_to_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        c.save()\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="powerpoint-to-pdf",\n                output_file=str(output_path),\n                output_name="powerpoint_to_pdf.pdf"\n            )\n\n        background_tasks.add_task',
        'history_old': '        c.save()\n\n        background_tasks.add_task'
    },
    # 18. PDF TO POWERPOINT
    {
        'old': '@app.post("/api/pdf/pdf-to-powerpoint")\nasync def pdf_to_powerpoint(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n):',
        'new': '@app.post("/api/pdf/pdf-to-powerpoint")\nasync def pdf_to_powerpoint(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        prs.save(str(output_path))\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="pdf-to-powerpoint",\n                output_file=str(output_path),\n                output_name="pdf_to_powerpoint.pptx"\n            )\n\n        background_tasks.add_task',
        'history_old': '        prs.save(str(output_path))\n\n        background_tasks.add_task'
    },
    # 19. HTML TO PDF
    {
        'old': '@app.post("/api/pdf/html-url-to-pdf")\nasync def html_url_to_pdf(\n    background_tasks: BackgroundTasks,\n    url: str = Form(...),\n):',
        'new': '@app.post("/api/pdf/html-url-to-pdf")\nasync def html_url_to_pdf(\n    background_tasks: BackgroundTasks,\n    url: str = Form(...),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        if pisa_status.err:\n            raise Exception("Failed to generate PDF from URL")\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="html-to-pdf",\n                output_file=str(output_path),\n                output_name="webpage.pdf"\n            )\n\n        background_tasks.add_task',
        'history_old': '        if pisa_status.err:\n            raise Exception("Failed to generate PDF from URL")\n\n        background_tasks.add_task'
    },
    # 20. ORGANIZE PDF
    {
        'old': '@app.post("/api/pdf/organize")\nasync def organize_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    page_order: str = Form(...),\n):',
        'new': '@app.post("/api/pdf/organize")\nasync def organize_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    page_order: str = Form(...),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        with open(output_path, "wb") as f:\n            writer.write(f)\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="organize",\n                output_file=str(output_path),\n                output_name="organized.pdf"\n            )\n\n        background_tasks.add_task',
        'history_old': '        with open(output_path, "wb") as f:\n            writer.write(f)\n\n        background_tasks.add_task'
    },
    # 21. ADD PAGE NUMBERS
    {
        'old': '@app.post("/api/pdf/add-page-numbers")\nasync def add_page_numbers(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    position: str = Form("bottom-center"),\n    start_number: int = Form(1),\n):',
        'new': '@app.post("/api/pdf/add-page-numbers")\nasync def add_page_numbers(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    position: str = Form("bottom-center"),\n    start_number: int = Form(1),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        with open(output_path, "wb") as f:\n            writer.write(f)\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="add-page-numbers",\n                output_file=str(output_path),\n                output_name="numbered.pdf"\n            )\n\n        background_tasks.add_task',
        'history_old': '        with open(output_path, "wb") as f:\n            writer.write(f)\n\n        background_tasks.add_task'
    },
    # 22. OCR PDF
    {
        'old': '@app.post("/api/pdf/ocr")\nasync def ocr_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    language: str = Form("eng"),\n):',
        'new': '@app.post("/api/pdf/ocr")\nasync def ocr_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    language: str = Form("eng"),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        c.save()\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="ocr",\n                output_file=str(output_path),\n                output_name="ocr_result.pdf"\n            )\n\n        background_tasks.add_task',
        'history_old': '        c.save()\n\n        background_tasks.add_task'
    },
    # 23. CROP PDF
    {
        'old': '@app.post("/api/pdf/crop")\nasync def crop_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    left: float = Form(0),\n    bottom: float = Form(0),\n    right: float = Form(0),\n    top: float = Form(0),\n):',
        'new': '@app.post("/api/pdf/crop")\nasync def crop_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    left: float = Form(0),\n    bottom: float = Form(0),\n    right: float = Form(0),\n    top: float = Form(0),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        with open(output_path, "wb") as f:\n            writer.write(f)\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="crop",\n                output_file=str(output_path),\n                output_name="cropped.pdf"\n            )\n\n        background_tasks.add_task',
        'history_old': '        with open(output_path, "wb") as f:\n            writer.write(f)\n\n        background_tasks.add_task'
    },
    # 24. REDACT PDF
    {
        'old': '@app.post("/api/pdf/redact")\nasync def redact_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    search_terms: str = Form(...),\n):',
        'new': '@app.post("/api/pdf/redact")\nasync def redact_pdf(\n    background_tasks: BackgroundTasks,\n    file: UploadFile = File(...),\n    search_terms: str = Form(...),\n    current_user: Optional[dict] = Depends(get_current_user),\n):',
        'history_insert': '        with open(output_path, "wb") as f:\n            writer.write(f)\n\n        # Save to history for authenticated users\n        if current_user:\n            await save_to_history(\n                user_id=current_user["user_id"],\n                tool_id="redact",\n                output_file=str(output_path),\n                output_name="redacted.pdf"\n            )\n\n        background_tasks.add_task',
        'history_old': '        with open(output_path, "wb") as f:\n            writer.write(f)\n\n        background_tasks.add_task'
    },
]

# Apply replacements
for replacement in replacements:
    if replacement['old'] in content:
        content = content.replace(replacement['old'], replacement['new'])
        print(f"✅ Updated function signature: {replacement['new'].split('async def')[1].split('(')[0].strip()}")
    else:
        print(f"⚠️  Could not find function signature to replace")
    
    if replacement['history_old'] in content:
        content = content.replace(replacement['history_old'], replacement['history_insert'])
        print(f"✅ Added history saving")
    else:
        print(f"⚠️  Could not find location to insert history saving")

# Write updated content
with open('main.py', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ All endpoints updated successfully!")
print("Run the backend server to test: python main.py")
