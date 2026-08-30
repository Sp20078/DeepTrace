"""
DeepTrace — AI Deepfake Investigator
=====================================
Clean backend rebuild. Single /analyze endpoint.
No mock data — everything comes from real model inference.
"""

import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers.analyze import router as analyze_router

app = FastAPI(
    title="DeepTrace API",
    description="AI-powered digital media forensics for deepfake detection.",
    version="2.0.0",
)

# CORS — allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analyze_router)


@app.get("/", tags=["General"])
def root():
    return {
        "message": "DeepTrace — AI Deepfake Investigator",
        "version": "2.0.0",
        "docs": "/docs",
    }


@app.get("/health", tags=["General"])
def health():
    return {
        "status": "healthy",
        "service": "deeptrace-backend",
        "version": "2.0.0",
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }


if __name__ == "__main__":
    import uvicorn
    print("🔬 Starting DeepTrace backend v2...")
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
