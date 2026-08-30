"""
DeepTrace History Router
========================
Endpoints for retrieving analysis history.
"""

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from services.history import get_history, get_analysis, get_stats
from services.report_generator import generate_report_pdf

router = APIRouter()


@router.get("/history", tags=["History"])
async def list_history(limit: int = 50):
    """
    Get analysis history.
    
    Returns a list of past analyses sorted by newest first.
    """
    history = get_history(limit=limit)
    return {
        "count": len(history),
        "history": history,
    }


@router.get("/history/stats", tags=["History"])
async def history_stats():
    """
    Get history statistics.
    
    Returns counts of total, high-risk, medium-risk, and low-risk analyses.
    """
    return get_stats()


@router.get("/history/{analysis_id}", tags=["History"])
async def get_analysis_detail(analysis_id: str):
    """
    Get full details for a specific analysis.
    """
    result = get_analysis(analysis_id)
    if not result:
        raise HTTPException(status_code=404, detail=f"Analysis {analysis_id} not found")
    return result


@router.get("/history/{analysis_id}/report", tags=["History"])
async def download_report(analysis_id: str):
    """
    Generate and download a PDF forensic report for an analysis.
    """
    result = get_analysis(analysis_id)
    if not result:
        raise HTTPException(status_code=404, detail=f"Analysis {analysis_id} not found")
    
    try:
        pdf_path = generate_report_pdf(result)
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate report: {e}")
    
    filename = f"DeepTrace_Report_{analysis_id}.pdf"
    return FileResponse(
        pdf_path,
        media_type="application/pdf",
        filename=filename,
    )
