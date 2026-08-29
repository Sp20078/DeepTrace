# 🔬 DeepTrace Backend

> AI-powered digital media forensics — Backend API

---

## 📋 Prerequisites

- **Python 3.8+** (tested with 3.13)
- **pip** (comes with Python)
- **FFmpeg** (for future video processing — not required yet)

---

## 🚀 Quick Start

### 1. Navigate to the backend directory

```bash
cd backend
```

### 2. Create a virtual environment

```bash
# Windows
py -m venv .venv
.venv\Scripts\activate

# macOS / Linux
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Start the development server

```bash
# Option A — via uvicorn (recommended)
uvicorn main:app --reload --host 127.0.0.1 --port 8000

# Option B — run the file directly
python main.py
```

### 5. Open the interactive API docs

Navigate to **http://127.0.0.1:8000/docs** in your browser.
FastAPI auto-generates Swagger documentation for all endpoints.

---

## 🧪 Testing the Endpoints

### Root endpoint

```bash
curl http://127.0.0.1:8000/
```

Expected response:
```json
{
  "message": "Welcome to DeepTrace — AI Deepfake Investigator",
  "version": "0.1.0",
  "phase": 1,
  "docs": "/docs"
}
```

### Health check endpoint

```bash
curl http://127.0.0.1:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "deeptrace-backend",
  "version": "0.1.0",
  "timestamp": "2026-08-30T..."
}
```

### File upload endpoint

```bash
curl -X POST http://127.0.0.1:8000/upload \
  -F "file=@sample_image.jpg"
```

Expected response (success):
```json
{
  "success": true,
  "message": "File uploaded successfully.",
  "file_id": "a1b2c3d4e5f6.jpg",
  "filename": "sample_image.jpg",
  "media_type": "image/jpeg",
  "media_category": "image",
  "file_size": 245760,
  "file_size_mb": 0.23,
  "stored_path": "backend/uploads/a1b2c3d4e5f6.jpg"
}
```

Expected response (error — unsupported format):
```json
{
  "detail": "Unsupported file type: 'application/pdf'. Supported formats: AVI, BMP, JPEG, MKV, MOV, MP4, PNG, TIFF, WebM, WebP"
}
```

**Supported formats:**
- Images: JPEG, PNG, WebP, BMP, TIFF
- Videos: MP4, MOV, AVI, WebM, MKV
- **Max size:** 100 MB

---

## 📁 Project Structure

```
backend/
├── main.py                  # FastAPI application entry point
├── requirements.txt         # Python dependencies
├── README.md                # This file
├── .gitignore               # Git ignore rules
├── routers/
│   ├── __init__.py
│   └── upload.py            # POST /upload endpoint
├── services/
│   ├── __init__.py
│   └── file_handler.py      # File validation, storage, metadata
├── utils/                   # Utility functions (future phases)
│   └── __init__.py
├── storage/                 # Temporary file storage (future phases)
└── uploads/                 # Uploaded files saved here
```

---

## 🔮 Phases

| Phase | Status | What's Added |
|-------|--------|-------------|
| **Phase 1** | ✅ Done | Basic FastAPI server, health endpoint |
| **Phase 2** | ✅ Done | File upload endpoint with validation |
| **Phase 3** | 🔜 Next | OpenCV preprocessing, AI/ML model integration |
| **Phase 4** | 🔜 | Risk scoring, evidence generation, forensic reports |
| **Phase 5** | 🔜 | Database, authentication, production hardening |

---

## 🛠 Development Notes

- The app uses **CORS middleware** configured to allow all origins (for development).
  In production, restrict `allow_origins` to your frontend domain.
- Run `uvicorn main:app --reload` during development for auto-reload on code changes.
- Uploaded files are saved to `backend/uploads/` with UUID-based names.
- Future routers (analysis, reports) are added in `routers/` and registered in `main.py`.
