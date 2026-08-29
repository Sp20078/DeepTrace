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

The deepfake detection model (EfficientNet-B0 fine-tuned on FaceForensics++) is downloaded **automatically** on first run. Weights are cached in `backend/model_weights/`.

### 3. Start the Backend

```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

The server will:
1. Load the EfficientNet-B0 deepfake model (~16MB download on first run)
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

### Model Selected: EfficientNet-B0 (FaceForensics++ C23 Fine-tuned)

**Why this model:**
1. Fine-tuned specifically on deepfake detection (FaceForensics++ C23 dataset)
2. Trained on multiple manipulation types: DeepFake, FaceSwap, Face2Face, NeuralTextures
3. Lightweight and fast on CPU (~10ms per face)
4. 224x224 input — standard size for face crops
5. Auto-downloads 16MB weights on first run
6. Research/educational license suitable for hackathons

**Source:** [Xicor9/efficientnet-b0-ffpp-c23](https://huggingface.co/Xicor9/efficientnet-b0-ffpp-c23) on Hugging Face

**License:** Research/educational use only

**Performance (on FaceForensics++ validation set):**
- AUC: 0.933
- Accuracy: 0.852
- F1-Score: 0.843

**Input requirements:**
- Shape: (batch, 3, 224, 224) — RGB, NCHW
- Normalization: ToTensor() converts to [0,1] float
- No ImageNet normalization needed

**Output:**
- 2-class softmax: [real_prob, fake_prob]
- manipulation_score: float [0, 1] — fake probability (higher = more likely manipulated)
- prediction: "Likely Authentic" / "Inconclusive" / "Likely Manipulated"

**Thresholds:**
- Fake prob ≥ 0.50: Likely Manipulated
- Fake prob ≤ 0.35: Likely Authentic
- Between: Inconclusive

**Known limitations:**
- Trained on FaceForensics++ C23 (compressed video frames)
- May produce high scores for any face image due to domain bias
- Best results with FaceForensics++ style video frames
- For production, consider models trained on larger/more diverse datasets

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
│   ├── ai_detector.py       # PyTorch: EfficientNet-B0 deepfake detector
│   └── analysis.py          # Pipeline orchestrator
├── uploads/                 # Uploaded files (gitignored)
├── model_weights/           # Downloaded model weights (gitignored)
└── utils/                   # Utility functions
```

---

## Troubleshooting

### CORS errors
The backend allows all origins in development. If you still get CORS errors, make sure you're hitting `http://127.0.0.1:8000` (not `localhost`).

### Model download fails
If the model weights can't be downloaded, check your internet connection. The weights are cached in `backend/model_weights/` after first download. You can also manually download from [Hugging Face](https://huggingface.co/Xicor9/efficientnet-b0-ffpp-c23) and place the .pth file in `backend/model_weights/`.

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
