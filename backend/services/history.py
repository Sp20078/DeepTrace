"""
DeepTrace History Service
=========================
Stores and retrieves analysis history.
Uses a simple JSON file for persistence.
"""

import json
import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

HISTORY_DIR = Path(__file__).parent.parent / "data" / "history"
HISTORY_FILE = HISTORY_DIR / "analyses.json"


def _ensure_dir():
    """Create history directory if it doesn't exist."""
    HISTORY_DIR.mkdir(parents=True, exist_ok=True)


def _load_history() -> list[dict]:
    """Load history from JSON file."""
    _ensure_dir()
    if not HISTORY_FILE.exists():
        return []
    try:
        with open(HISTORY_FILE, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        logger.warning("Failed to load history: %s", e)
        return []


def _save_history(history: list[dict]):
    """Save history to JSON file."""
    _ensure_dir()
    with open(HISTORY_FILE, "w") as f:
        json.dump(history, f, indent=2, default=str)


def save_analysis(result: dict):
    """
    Save an analysis result to history.
    
    Extracts key fields for the history list and stores the full result
    for later PDF generation.
    """
    history = _load_history()
    
    # Create history entry with key fields
    entry = {
        "analysis_id": result.get("analysis_id", ""),
        "filename": result.get("filename", ""),
        "media_type": result.get("media_type", ""),
        "media_category": result.get("media_category", "image"),
        "prediction": result.get("prediction", ""),
        "risk_score": result.get("risk_score", 0),
        "risk_level": result.get("risk_level", "MINIMAL"),
        "faces_detected": result.get("faces_detected", 0),
        "frames_analyzed": result.get("frames_analyzed", 0),
        "timestamp": result.get("timestamp", ""),
        "model": result.get("model", ""),
        # Store full result for PDF generation
        "full_result": result,
    }
    
    # Add to beginning of list (newest first)
    history.insert(0, entry)
    
    # Keep only last 100 entries
    if len(history) > 100:
        history = history[:100]
    
    _save_history(history)
    logger.info("Saved analysis %s to history", entry["analysis_id"])


def get_history(limit: int = 50) -> list[dict]:
    """
    Get analysis history.
    
    Returns list of history entries (without full_result for efficiency).
    """
    history = _load_history()
    
    # Return entries without full_result (too large for list view)
    entries = []
    for item in history[:limit]:
        entry = {k: v for k, v in item.items() if k != "full_result"}
        entries.append(entry)
    
    return entries


def get_analysis(analysis_id: str) -> Optional[dict]:
    """
    Get a specific analysis by ID.
    
    Returns the full result dict including all details for PDF generation.
    """
    history = _load_history()
    
    for item in history:
        if item.get("analysis_id") == analysis_id:
            return item.get("full_result")
    
    return None


def get_stats() -> dict:
    """Get history statistics."""
    history = _load_history()
    
    total = len(history)
    high_risk = sum(1 for h in history if h.get("risk_level") == "HIGH")
    medium_risk = sum(1 for h in history if h.get("risk_level") == "MEDIUM")
    low_risk = sum(1 for h in history if h.get("risk_level") in ("LOW", "MINIMAL"))
    
    return {
        "total": total,
        "high_risk": high_risk,
        "medium_risk": medium_risk,
        "low_risk": low_risk,
    }


def clear_history():
    """Clear all history."""
    _save_history([])
    logger.info("History cleared")
