# PDF Tools — Startup Guide

## Project Structure

```
PDF/
├── backend/               # Python FastAPI backend
│   ├── main.py            # All PDF API endpoints
│   ├── database.py        # PostgreSQL connection
│   ├── models.py          # SQLAlchemy ORM models
│   ├── schema.sql         # Raw SQL schema (run once)
│   ├── requirements.txt   # Python dependencies
│   ├── .env.example       # Environment variable template
│   └── temp_files/        # Temporary uploaded files (auto-created)
│
└── frontend/              # Flutter application
    ├── lib/
    │   ├── main.dart              # App entry point
    │   ├── core/
    │   │   ├── app_theme.dart     # Light & dark theme
    │   │   └── api_config.dart    # Backend URL config
    │   ├── data/
    │   │   └── tools_data.dart    # All 11 tool definitions
    │   ├── models/
    │   │   └── pdf_tool.dart      # PdfTool data model
    │   ├── providers/
    │   │   └── theme_provider.dart
    │   ├── screens/
    │   │   ├── home_screen.dart   # Landing page
    │   │   └── tool_screen.dart   # Per-tool page
    │   ├── services/
    │   │   └── pdf_api_service.dart  # Dio HTTP service
    │   └── widgets/
    │       ├── app_navbar.dart
    │       ├── hero_section.dart
    │       ├── feature_banner.dart
    │       ├── tool_card.dart
    │       ├── drop_zone_widget.dart
    │       └── processing_panel.dart
    └── pubspec.yaml
```

---

## 1. Backend Setup (FastAPI)

### Prerequisites
- Python 3.11+
- PostgreSQL (optional for basic use)

### Steps

```powershell
cd "d:\Flutter Projects\PDF\backend"

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# (Optional) Set up PostgreSQL
# 1. Create DB:  createdb pdftools
# 2. Run schema: psql -d pdftools -f schema.sql
# 3. Copy env:   copy .env.example .env  (then edit DATABASE_URL)

# Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at: **http://localhost:8000**  
Interactive API docs: **http://localhost:8000/docs**

---

## 2. Frontend Setup (Flutter)

### Prerequisites
- Flutter SDK 3.x
- Chrome browser (for web development)

### Steps

```powershell
cd "d:\Flutter Projects\PDF\frontend"

# Get packages
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Or run on Windows desktop
flutter run -d windows
```

---

## 3. Available API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/pdf/merge` | Merge multiple PDFs |
| POST | `/api/pdf/split` | Split PDF by range or every page |
| POST | `/api/pdf/compress` | Compress PDF file size |
| POST | `/api/pdf/rotate` | Rotate PDF pages |
| POST | `/api/pdf/watermark` | Add text watermark |
| POST | `/api/pdf/protect` | Password-protect PDF |
| POST | `/api/pdf/unlock` | Remove PDF password |
| POST | `/api/pdf/images-to-pdf` | Convert images to PDF |
| POST | `/api/pdf/pdf-to-images` | Convert PDF pages to images (ZIP) |
| POST | `/api/pdf/info` | Get PDF metadata |
| POST | `/api/pdf/extract-text` | Extract text from PDF |

---

## 4. Changing the Backend URL

Edit `frontend/lib/core/api_config.dart`:
```dart
const String baseUrl = 'http://YOUR_SERVER_IP:8000';
```

---

## 5. Optional: pdf2image (PDF to JPG)

The `pdf-to-images` endpoint requires **Poppler**:
- Windows: Download from https://github.com/oschwartz10612/poppler-windows/releases
- Add the `bin/` folder to your system PATH

---

## 6. Deployment

### Backend (Railway / Render)
1. Push `backend/` folder to GitHub
2. Set `DATABASE_URL` environment variable
3. Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

### Frontend (Vercel / Firebase Hosting)
```powershell
flutter build web --release
# Deploy the `build/web` folder to Vercel or Firebase
```
