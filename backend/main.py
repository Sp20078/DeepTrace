"""
DeepTrace — AI Deepfake Investigator
=====================================
Backend entry point (Phase 2: File Upload API)

This module creates and configures the FastAPI application instance.
It provides basic endpoints and mounts routers for file upload.

Future phases will extend this file by:
  - Adding routers for analysis, reports, etc.
  - Connecting to AI/ML services (OpenCV, PyTorch models)
  - Adding database connections and authentication middleware
"""

import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers.upload import router as upload_router
from routers.analysis import router as analysis_router

# ---------------------------------------------------------------------------
# App Configuration
# ---------------------------------------------------------------------------

# Create the FastAPI application instance.
# Metadata here shows up in the auto-generated docs at /docs
app = FastAPI(
    title="DeepTrace API",
    description=(
        "AI-powered digital media forensics for detecting suspicious "
        "manipulation and providing explainable evidence."
    ),
    version="0.1.0",
)

# ---------------------------------------------------------------------------
# Middleware
# ---------------------------------------------------------------------------

# CORS configuration for development.
# Flutter web runs on http://localhost:PORT — must allow it.
# In production, restrict to the actual frontend domain.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "*",
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
# Register route modules. Each router defines a group of related endpoints.
# New routers (reports, etc.) will be added here in future phases.
app.include_router(upload_router)
app.include_router(analysis_router)


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@app.get("/", tags=["General"])
def root():
    """
    Root endpoint — confirms the DeepTrace backend is running.

    Returns a simple welcome message with basic API info.
    """
    return {
        "message": "Welcome to DeepTrace — AI Deepfake Investigator",
        "version": "0.1.0",
        "phase": 1,
        "docs": "/docs",
    }


@app.get("/health", tags=["General"])
def health_check():
    """
    Health check endpoint — useful for monitoring, load balancers,
    and verifying the service is alive and responding.

    Returns the current server status and timestamp.
    """
    return {
        "status": "healthy",
        "service": "deeptrace-backend",
        "version": "0.1.0",
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }


# ---------------------------------------------------------------------------
# Direct execution (development convenience)
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    # This block lets you run the server directly:
    #   python main.py
    #
    # In production, prefer running via uvicorn:
    #   uvicorn main:app --host 0.0.0.0 --port 8000
    import uvicorn

    print("🔬 Starting DeepTrace backend...")
    uvicorn.run(app, host="127.0.0.1", port=8000, reload=True)
