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

### Analysis endpoint

```bash
curl -X POST http://127.0.0.1:8000/analyze \
  -F "file=@sample_image.jpg"
```

Expected response (mock — AI model not yet integrated):
```json
{
  "analysis_id": "a1b2c3d4e5f6...",
  "status": "completed",
  "media_type": "image/jpeg",
  "media_category": "image",
  "message": "Mock analysis complete. AI model not yet integrated.",
  "timestamp": "2026-08-30T...",
  "file_path": "backend/uploads/a1b2c3d4e5f6.jpg",
  "results": {
    "risk_score": 0,
    "risk_level": "pending",
    "confidence": 0.0,
    "components": {
      "facial_analysis": { "score": null, "status": "awaiting_model" },
      "temporal_analysis": { "score": null, "status": "awaiting_model" },
      "visual_analysis": { "score": null, "status": "awaiting_model" }
    },
    "evidence_flags": [],
    "suspicious_segments": [],
    "recommendations": ["Awaiting AI model integration for full analysis."]
  }
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
│   ├── upload.py            # POST /upload endpoint
│   └── analysis.py          # POST /analyze endpoint
├── services/
│   ├── __init__.py
│   ├── file_handler.py      # File validation, storage, metadata
│   ├── analysis.py          # Analysis pipeline (mock -> real)
│   └── media_processor.py   # OpenCV media reading & metadata extraction
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
| **Phase 3** | ✅ Done | Analysis endpoint with mock pipeline |
| **Phase 4** | 🔜 Next | AI/ML deepfake detection model integration |
| **Phase 5** | 🔜 | Risk scoring, evidence generation, forensic reports |
| **Phase 6** | 🔜 | Database, authentication, production hardening |

---

## 🛠 Development Notes

- The app uses **CORS middleware** configured to allow all origins (for development).
  In production, restrict `allow_origins` to your frontend domain.
- Run `uvicorn main:app --reload` during development for auto-reload on code changes.
- Uploaded files are saved to `backend/uploads/` with UUID-based names.
- Future routers (analysis, reports) are added in `routers/` and registered in `main.py`.

---

## 🔬 Media Processor (OpenCV)

The `services/media_processor.py` module provides OpenCV-based media reading
and frame extraction.

### Metadata Extraction

| Function | Purpose |
|----------|---------|
| `read_image_info(path)` | Extract width, height, channels, format from an image |
| `read_video_info(path)` | Extract width, height, FPS, frame count, duration, codec from a video |
| `read_media_info(path)` | Auto-detect image vs video and extract metadata |

### Frame Extraction

| Function | Purpose |
|----------|---------|
| `extract_frames(path, fps=N)` | Extract N frames per second |
| `extract_frames(path, interval=N)` | Extract one frame every N seconds |
| `extract_frames(path, max_frames=N)` | Extract exactly N evenly-spaced frames |
| `extract_single_frame(path, timestamp=N)` | Extract a single frame at N seconds |
| `cleanup_frames(output_dir)` | Delete extracted frame files to free disk |

Frame metadata includes: `frame_number`, `timestamp`, `timestamp_fmt`, `width`, `height`, `path`.

All functions raise `MediaError` for invalid/corrupted/missing files.
Safety limit: max 500 frames per extraction (configurable via `MAX_FRAMES`).

---

## Face Detection & AI Preprocessing

The `services/face_detector.py` module provides face detection and
preprocessing for the future AI model.

### Face Detection

| Function | Purpose |
|----------|---------|
| `detect_faces(frame)` | Detect faces in a BGR frame, return bounding boxes |
| `detect_faces_in_image(path)` | Load image + detect faces |
| `crop_faces(frame, faces)` | Crop face regions with optional padding |

### Preprocessing for AI

| Function | Purpose |
|----------|---------|
| `preprocess_face(crop, target_size, color_mode)` | Resize + convert color + normalize |
| `preprocess_faces(crops, ...)` | Batch preprocess multiple face crops |

Configurable: `target_size` (default 224x224), `color_mode` (bgr/rgb/gray), `normalize` (float32 [0,1]).

### High-Level Pipeline

| Function | Purpose |
|----------|---------|
| `process_frame_for_ai(frame, ...)` | Detect + crop + preprocess a single frame |
| `process_image_for_ai(path, ...)` | Full pipeline for an image file |
| `process_video_frames_for_ai(frames, ...)` | Process extracted frames from a video |

Output includes `ai_inputs`: a flat list of numpy arrays ready for batch model inference.
