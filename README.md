# 🔎 DeepTrace

### Don't just detect. Investigate.

> AI-powered digital media forensics for detecting suspicious manipulation and providing explainable evidence.

**Upload → Analyze → Detect → Investigate → Report**

---

## 📖 About

DeepTrace is an AI-powered digital media forensics platform that goes beyond binary real/fake classification. It provides an **explainable investigation experience** — surfacing risk scores, suspicious timestamps, evidence signals, and forensic-style reports so that analysts, journalists, and everyday users can **understand why** a piece of media may have been manipulated.

## 🧩 Problem Statement

Deepfakes and synthetic media are evolving faster than our ability to counter them. Most existing tools offer a single output — *real* or *fake* — with no reasoning, no context, and no evidence. This leaves users blind to **where**, **when**, and **why** manipulation may have occurred.

> **We don't need another black-box classifier. We need a forensic investigation tool.**

## 💡 Our Solution

DeepTrace provides a **multi-stage forensic pipeline** that ingests images or videos and produces a structured, explainable report:

| Stage | What it does |
|-------|-------------|
| **Media Preprocessing** | Normalizes input, extracts metadata, prepares frames |
| **Face Detection** | Identifies and isolates faces for targeted analysis |
| **AI Classification** | Runs deep learning models for manipulation detection |
| **Frame-Level Analysis** | Scores each frame independently for granular insight |
| **Temporal Aggregation** | Identifies suspicious time segments and anomalies |
| **Evidence Generation** | Flags specific artifacts — facial inconsistencies, temporal jumps, visual distortions |
| **Risk Scoring** | Produces a weighted, explainable risk score with component breakdowns |
| **Forensic Report** | Compiles everything into a structured, shareable report |

## 🏆 The DeepTrace Difference

| Capability | Traditional Detector | DeepTrace |
|-----------|---------------------|-----------|
| Output | ✅ / ❌ binary label | Risk score + evidence + timeline |
| Explainability | None | Full breakdown with flagged signals |
| Frame-level analysis | ❌ | ✅ Suspicious timestamps & evidence frames |
| Temporal awareness | ❌ | ✅ Identifies manipulation segments |
| Forensic report | ❌ | ✅ Structured, exportable report |
| Investigator UX | Score display | Interactive timeline + evidence viewer |
| Human-in-the-loop | No guidance | Recommends human verification |

> Detection is the starting point. **Explainability is the destination.**

## ✨ Key Features

- 🎯 **Multi-Signal Risk Scoring** — Facial, temporal, and visual analysis combined into one explainable score
- 🔍 **Suspicious Timestamp Detection** — Pinpoints exact frames and time ranges of concern
- 🖼️ **Evidence Frame Visualization** — Shows the actual frames that triggered alerts
- 📊 **Interactive Investigation Timeline** — Explore manipulation signals across the full video duration
- 📝 **Forensic Report Generation** — Structured report with findings, evidence, and recommendations
- 🎥 **Image & Video Support** — Analyze single images or full video files
- 🧠 **Explainable AI** — Every prediction comes with a breakdown of contributing factors
- 🔒 **Privacy-First Processing** — Minimal media retention, local processing by default
- ⚡ **Fast Inference** — Optimized pipeline for quick turnaround on analysis

## ⚙️ How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        DeepTrace Pipeline                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────────┐   │
│  │  Upload   │───▶│ Preprocessing │───▶│  Frame Extraction    │   │
│  │ Image/Video│   │  & Metadata   │   │  (videos only)       │   │
│  └──────────┘    └──────────────┘    └──────────┬───────────┘   │
│                                                   │               │
│                                                   ▼               │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                  Face Detection & ROI Extraction          │    │
│  └────────────────────────┬─────────────────────────────────┘    │
│                            │                                      │
│                            ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │               AI Deepfake Detection Model                 │    │
│  │          (PyTorch · Frame-level predictions)              │    │
│  └────────────────────────┬─────────────────────────────────┘    │
│                            │                                      │
│                            ▼                                      │
│  ┌──────────────┐  ┌───────────────┐  ┌────────────────────┐    │
│  │  Facial       │  │  Temporal      │  │  Visual Artifact   │    │
│  │  Analysis     │  │  Analysis      │  │  Analysis          │    │
│  └──────┬───────┘  └───────┬───────┘  └─────────┬──────────┘    │
│         │                  │                     │                 │
│         └──────────┬───────┴─────────────────────┘                │
│                    ▼                                              │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │            Risk Aggregation & Scoring Engine              │    │
│  └────────────────────────┬─────────────────────────────────┘    │
│                            │                                      │
│                            ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │              Forensic Report Generation                   │    │
│  │   Risk Score · Evidence Frames · Timeline · Findings      │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 🧠 AI/ML Pipeline

DeepTrace's detection pipeline operates across three analysis streams:

| Stream | Model / Technique | Purpose |
|--------|------------------|---------|
| **Facial Analysis** | CNN-based face forgery detector | Detects blending artifacts, warping, inconsistencies in facial regions |
| **Temporal Analysis** | Frame-to-frame coherence scoring | Identifies unnatural transitions, flickering, and temporal inconsistencies |
| **Visual Analysis** | Artifact detection network | Catches noise pattern anomalies, compression artifacts, and resolution inconsistencies |

Each stream produces independent signals that are fused by the **Risk Aggregation Engine** into a single, interpretable score with component-level breakdowns.

### Training & Datasets

The models in this project are trained and evaluated using established public benchmarks:

| Dataset | Description | Usage |
|---------|-------------|-------|
| [FaceForensics++](https://github.com/ondyari/FaceForensics) | 1,000 original + 4,000 manipulated videos with 4 manipulation methods | Primary training and evaluation |
| [DeeperForensics-1.0](https://github.com/EndlessSora/DeeperForensics-1.0) | 60,000 videos with rich manipulation attributes | Robustness and generalization testing |
| [DFDC](https://dfdc.ai/) (where appropriate) | 124K videos from 3,426 paid actors | Cross-dataset evaluation |

> **Note:** This repository does not include complete datasets. See each dataset's official source for access and licensing.

## 🛠️ Technology Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | React, Tailwind CSS, JavaScript / TypeScript |
| **Backend** | Python, FastAPI |
| **AI/ML** | PyTorch, OpenCV, NumPy |
| **Media Processing** | FFmpeg, OpenCV |
| **Visualization** | Interactive timeline, evidence viewer |



### Methodology

Models are evaluated using standard cross-validation protocols on the datasets listed above. Evaluation is performed on **unseen test splits** with metrics reported as **placeholders** until formal experiments are completed.

> ⚠️ The metrics below are **placeholders**. Final numbers will be updated after completed evaluation runs.

### Results

| Metric | Value | Notes |
|--------|-------|-------|
| **Accuracy** | `--` | Pending full evaluation |
| **Precision** | `--` | Pending full evaluation |
| **Recall** | `--` | Pending full evaluation |
| **F1 Score** | `--` | Pending full evaluation |
| **AUC-ROC** | `--` | Pending full evaluation |

*Results will be updated after completing the final evaluation benchmark.*

### Evaluation Protocol

- **Train/Val/Test Split** — Standard protocol per dataset guidelines
- **Cross-Dataset Testing** — Models trained on one dataset evaluated on another to test generalization
- **Threshold Selection** — Optimized on validation set using F1 score
- **Reporting** — Per-frame and per-video metrics reported separately

## 🔒 Privacy & Security

| Principle | Implementation |
|-----------|---------------|
| **Minimal Retention** | Uploaded media is processed and deleted after analysis completes |
| **Local Processing** | All inference runs locally by default — no cloud upload required |
| **No Data Collection** | No user data, analytics, or tracking beyond what is necessary for functionality |
| **Secure Handling** | Files are stored in memory or temporary directories with automatic cleanup |

## ⚡ Performance Optimization

- **Batch Frame Processing** — Frames are processed in optimized batches to maximize GPU/CPU utilization
- **Model Quantization** — Optional INT8 quantization for faster inference on edge devices
- **Parallel Pipeline Stages** — Preprocessing and frame extraction overlap with model loading
- **Incremental Analysis** — Video frames are processed incrementally to reduce peak memory usage

## 🚀 Getting Started

### Prerequisites

- **Python** 3.8+
- **Node.js** 16+
- **FFmpeg** installed and available on `PATH`
- **CUDA** (optional, for GPU acceleration)


## 🎬 Usage

1. **Upload** — Drag and drop an image or video file, or click to browse
2. **Analyze** — DeepTrace preprocesses the media and runs the detection pipeline
3. **Investigate** — Review the risk score, flagged evidence frames, and suspicious timeline
4. **Report** — Export a structured forensic report with findings and recommendations

## 📋 Example Forensic Report

```
╔══════════════════════════════════════════════════╗
║           DEEPTRACE FORENSIC REPORT              ║
╠══════════════════════════════════════════════════╣
║  File: sample_video.mp4                          ║
║  Date: 2026-08-27                                ║
║  Duration: 00:32                                 ║
╠══════════════════════════════════════════════════╣
║                                                  ║
║  OVERALL RISK SCORE:  87% — HIGH RISK ⚠️        ║
║                                                  ║
║  ┌────────────────────────────────────────┐      ║
║  │ Component Breakdown                    │      ║
║  │                                        │      ║
║  │  Facial Analysis      ██████████░  92% │      ║
║  │  Temporal Analysis    ████████░░░  81% │      ║
║  │  Visual Analysis      █████████░░  89% │      ║
║  └────────────────────────────────────────┘      ║
║                                                  ║
║  SUSPICIOUS SEGMENT:  00:14 → 00:16             ║
║                                                  ║
║  EVIDENCE FLAGS:                                 ║
║    • Facial inconsistency (score: 0.91)          ║
║    • Temporal anomaly (score: 0.78)              ║
║    • Visual artifacts detected (score: 0.85)     ║
║                                                  ║
║  ASSESSMENT: AI analysis indicates high          ║
║  probability of manipulation. Human review       ║
║  recommended for final determination.            ║
║                                                  ║
╚══════════════════════════════════════════════════╝
```


## 🎯 Use Cases

| Sector | Application |
|--------|------------|
| **Journalism & Media** | Verify video/image authenticity before publication |
| **Legal & Compliance** | Assess digital evidence integrity |
| **Social Media** | Flag potentially manipulated content for review |
| **Academic Research** | Study deepfake detection techniques and artifacts |
| **Cybersecurity** | Investigate synthetic media in fraud or disinformation campaigns |

## ⚠️ Limitations

- **Not a definitive proof tool** — DeepTrace provides AI-assisted assessments, not final verdicts
- **Performance varies** — Detection accuracy may differ across manipulation types not seen during training
- **Resource dependent** — Full pipeline requires adequate compute for real-time video analysis
- **Model bias** — Trained on specific datasets; may not generalize equally to all manipulation techniques
- **No real-time streaming** — Current version processes uploaded files, not live feeds

> DeepTrace is designed to **assist human investigators**, not replace them. Always verify AI findings with expert judgment.


## 👥 Team

| Name | Role | Contact |
|------|------|---------|
| SAIYAM PATIL | AI/ML 
| VASADI PRANEETH SAI RAJ | Full-Stack Developer 
| KONCHADA SHANMUKHA SHASWATH | Frontend & UI/UX
| ADITYA PANDEY | Backend & Infrastructure

## 🏅 Hackathon

| Detail | Info |
|--------|------|
| **Hackathon** | DEVJAMS 26' |
| **Date** | 29th August |
| **Team Name** | sudo rm -rf |


---

<p align="center">
  <b>DeepTrace transforms deepfake detection from a simple prediction into an explainable forensic investigation.</b>
</p>

<p align="center">

</p>
