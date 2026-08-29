# 🔬 DeepTrace Backend

> AI-powered digital media forensics — Backend API

---

## 📋 Prerequisites

- **Python 3.8+** (tested with 3.13)
- **pip** (comes with Python)
- **FFmpeg** (for future video processing — not required for Phase 1)

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

---

## 📁 Project Structure

```
backend/
├── main.py              # FastAPI application entry point
├── requirements.txt     # Python dependencies
├── README.md            # This file
├── .gitignore           # Git ignore rules
├── services/            # Business logic (future phases)
│   └── __init__.py
├── utils/               # Utility functions (future phases)
│   └── __init__.py
└── storage/             # Temporary file storage (future phases)
```

---

## 🔮 Future Phases

| Phase | What's Added |
|-------|-------------|
| **Phase 2** | File upload endpoint, OpenCV preprocessing |
| **Phase 3** | AI/ML model integration (PyTorch deepfake detection) |
| **Phase 4** | Risk scoring, evidence generation, forensic reports |
| **Phase 5** | Database, authentication, production hardening |

New endpoints will be added via FastAPI routers in a `routers/` directory.
Dependencies will be added to `requirements.txt` as needed.

---

## 🛠 Development Notes

- The app uses **CORS middleware** configured to allow all origins (for development).
  In production, restrict `allow_origins` to your frontend domain.
- Run `uvicorn main:app --reload` during development for auto-reload on code changes.
- The `storage/` directory is reserved for temporary file handling in future phases.
