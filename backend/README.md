# DeepTrace Backend

> AI-powered digital media forensics — Backend API

---

## HOW TO RUN DEEPTRACE

### Prerequisites

| Requirement | Version | Notes |
|------------|---------|-------|
| Python | 3.10+ | Tested with 3.13 |
| pip | Latest | Comes with Python |
| GPU (optional) | CUDA-capable | Falls back to CPU automatically |

### 1. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv .venv

# Activate (Windows)
.venv\Scripts\activate

# Activate (macOS/Linux)
source .venv/bin/activate

# Install all dependencies
pip install -r requirements.txt
```

### 2. AI Model Setup

The model (EfficientNet-B4) is downloaded **automatically** on first run by torchvision. No manual download is needed. Weights are cached in `~/.cache/torch/hub/`.

### 3. Start the Backend

```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

The server will:
1. Load the EfficientNet-B4 model (~75MB download on first run)
2. Start listening on `http://127.0.0.1:8000`
3. Show API docs at `http://127.0.0.1:8000/docs`

### 4. Test with curl

```bash
# Test health
curl http://127.0.0.1:8000/health

# Analyze an image
curl -X POST http://127.0.0.1:8000/analyze -F "file=@photo.jpg"

# Analyze a video
curl -X POST http://127.0.0.1:8000/analyze -F "file=@video.mp4"
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Welcome message |
| GET | `/health` | Server health check |
| POST | `/upload` | Upload a file (saves to disk) |
| POST | `/analyze` | Upload + analyze a file (full pipeline) |

---

## Architecture

```
Frontend (Flutter)
    ↓
FastAPI (POST /analyze)
    ↓
File validation (file_handler.py)
    ↓
Save to uploads/ (file_handler.py)
    ↓
┌─────────────────────────────────────────────┐
│ Analysis Pipeline (analysis.py)              │
│                                              │
│  Image? → OpenCV read → face detect → AI     │
│  Video? → frame extract → face detect → AI   │
│                                              │
│  OpenCV: media_processor.py + face_detector.py│
│  AI:     ai_detector.py (EfficientNet-B4)    │
└─────────────────────────────────────────────┘
    ↓
JSON response → Frontend
```

---

## AI Model Documentation

### Model Selected: EfficientNet-B4 (ImageNet Pretrained)

**Why this model:**
1. Strong feature extraction from ImageNet pretraining
2. Well-documented, maintained by PyTorch/torchvision team
3. Reasonable CPU inference speed (~50ms per face)
4. Good balance of accuracy and compute cost
5. 384x384 input resolution — compatible with face crops
6. No manual weight download required

**Source:** torchvision.models.efficientnet_b4 (Weights.IMAGENET1K_V1)

**License:** BSD-3-Clause (torchvision)

**Input requirements:**
- Shape: (batch, 3, 384, 384) — RGB, NCHW
- Normalization: ImageNet mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
- Values: [0, 1] float before normalization

**Output:**
- manipulation_score: float [0, 1] — higher = more likely manipulated
- prediction: "Likely Authentic" / "Inconclusive" / "Likely Manipulated"

**Thresholds:**
- Score ≥ 0.65: Likely Manipulated
- Score ≤ 0.35: Likely Authentic
- Between: Inconclusive

**Known limitations:**
- Pretrained on ImageNet (general images), NOT specifically on deepfake data
- For production, a model fine-tuned on FaceForensics++ or Celeb-DF would be needed
- Scores represent visual anomaly detection, not certified deepfake detection

---

## Project Structure

```
backend/
├── main.py                  # FastAPI app, CORS, routers
├── requirements.txt         # Python dependencies
├── README.md                # This file
├── .gitignore               # Git ignore rules
├── routers/
│   ├── upload.py            # POST /upload
│   └── analysis.py          # POST /analyze (real pipeline)
├── services/
│   ├── file_handler.py      # File validation, storage
│   ├── media_processor.py   # OpenCV: metadata, frame extraction
│   ├── face_detector.py     # OpenCV: Haar cascade face detection
│   ├── ai_detector.py       # PyTorch: EfficientNet-B4 inference
│   └── analysis.py          # Pipeline orchestrator
├── uploads/                 # Uploaded files (gitignored)
└── utils/                   # Utility functions
```

---

## Troubleshooting

### CORS errors
The backend allows all origins in development. If you still get CORS errors, make sure you're hitting `http://127.0.0.1:8000` (not `localhost`).

### Model download fails
If torchvision can't download weights, check your internet connection. The weights are cached at `~/.cache/torch/hub/` after first download.

### CUDA/GPU not detected
The system automatically falls back to CPU. GPU acceleration is optional. To force CPU: `CUDA_VISIBLE_DEVICES="" uvicorn main:app --reload`

### Port already in use
Use a different port: `uvicorn main:app --port 8001`

### Python version issues
Python 3.10+ is required. Python 3.13 is recommended.

### Large file uploads
Max file size is 100MB. Configured in `services/file_handler.py`.

---

## Supported Formats

**Images:** JPEG, PNG, WebP, BMP, TIFF
**Videos:** MP4, MOV, AVI, WebM, MKV
