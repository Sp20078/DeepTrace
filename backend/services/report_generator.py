"""
DeepTrace PDF Report Generator
==============================
Generates forensic investigation reports as PDF.
"""

import datetime
import logging
import tempfile
from pathlib import Path

logger = logging.getLogger(__name__)


def generate_report_pdf(result: dict) -> str:
    """
    Generate a PDF report from analysis results.
    
    Returns the path to the generated PDF file.
    """
    try:
        from reportlab.lib import colors
        from reportlab.lib.pagesizes import A4
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.units import inch, mm
        from reportlab.platypus import (
            SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
            HRFlowable, KeepTogether
        )
        from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
    except ImportError:
        raise RuntimeError(
            "reportlab not installed. Run: pip install reportlab"
        )
    
    # Create temp file for PDF
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".pdf")
    pdf_path = tmp.name
    tmp.close()
    
    # Build PDF
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=A4,
        rightMargin=50,
        leftMargin=50,
        topMargin=50,
        bottomMargin=50,
    )
    
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        spaceAfter=6,
        textColor=colors.HexColor('#6366f1'),
    )
    
    subtitle_style = ParagraphStyle(
        'CustomSubtitle',
        parent=styles['Normal'],
        fontSize=10,
        textColor=colors.grey,
        spaceAfter=20,
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=14,
        spaceBefore=16,
        spaceAfter=8,
        textColor=colors.HexColor('#1f2937'),
    )
    
    body_style = ParagraphStyle(
        'CustomBody',
        parent=styles['Normal'],
        fontSize=10,
        leading=14,
        spaceAfter=6,
    )
    
    label_style = ParagraphStyle(
        'Label',
        parent=styles['Normal'],
        fontSize=9,
        textColor=colors.grey,
    )
    
    value_style = ParagraphStyle(
        'Value',
        parent=styles['Normal'],
        fontSize=10,
        fontName='Helvetica-Bold',
    )
    
    # Content
    story = []
    
    # Header
    story.append(Paragraph("DEEPTRACE", title_style))
    story.append(Paragraph("AI-Powered Digital Forensics Report", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor('#6366f1')))
    story.append(Spacer(1, 20))
    
    # Report metadata
    analysis_id = result.get("analysis_id", "N/A")
    timestamp = result.get("timestamp", "")
    if timestamp:
        try:
            dt = datetime.datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
            timestamp = dt.strftime("%B %d, %Y at %H:%M:%S UTC")
        except:
            pass
    
    story.append(Paragraph(f"<b>Report ID:</b> {analysis_id}", body_style))
    story.append(Paragraph(f"<b>Generated:</b> {timestamp}", body_style))
    story.append(Paragraph(f"<b>Model:</b> {result.get('model', 'N/A')}", body_style))
    story.append(Spacer(1, 16))
    
    # Risk Assessment Box
    risk_score = result.get("risk_score", 0)
    risk_level = result.get("risk_level", "MINIMAL")
    prediction = result.get("prediction", "N/A")
    
    risk_color = {
        "HIGH": colors.HexColor('#ef4444'),
        "MEDIUM": colors.HexColor('#f59e0b'),
        "LOW": colors.HexColor('#22c55e'),
        "MINIMAL": colors.HexColor('#22c55e'),
    }.get(risk_level, colors.grey)
    
    risk_data = [
        [Paragraph("<b>RISK ASSESSMENT</b>", ParagraphStyle('RiskHeader', parent=body_style, textColor=colors.white, fontSize=12))],
        [
            Paragraph(f"<b>Score:</b> {risk_score} / 100", ParagraphStyle('RiskScore', parent=body_style, textColor=colors.white, fontSize=20)),
            Paragraph(f"<b>Level:</b> {risk_level}", ParagraphStyle('RiskLevel', parent=body_style, textColor=colors.white, fontSize=14)),
            Paragraph(f"<b>Prediction:</b> {prediction}", ParagraphStyle('RiskPred', parent=body_style, textColor=colors.white, fontSize=11)),
        ],
    ]
    
    risk_table = Table(risk_data, colWidths=[doc.width])
    risk_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), risk_color),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.white),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 12),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
        ('LEFTPADDING', (0, 0), (-1, -1), 16),
        ('RIGHTPADDING', (0, 0), (-1, -1), 16),
        ('ROUNDEDCORNERS', [8, 8, 8, 8]),
    ]))
    story.append(risk_table)
    story.append(Spacer(1, 20))
    
    # File Information
    story.append(Paragraph("File Information", heading_style))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#e5e7eb')))
    story.append(Spacer(1, 8))
    
    file_data = [
        ["Filename", result.get("filename", "N/A")],
        ["Media Type", result.get("media_type", "N/A").upper()],
        ["Faces Detected", str(result.get("faces_detected", 0))],
    ]
    
    if result.get("media_category") == "video":
        file_data.append(["Frames Analyzed", str(result.get("frames_analyzed", 0))])
    
    media_info = result.get("media_info", {})
    if media_info.get("width"):
        file_data.append(["Resolution", f"{media_info['width']}x{media_info['height']}"])
    if media_info.get("duration_fmt"):
        file_data.append(["Duration", media_info["duration_fmt"]])
    
    file_table = Table(file_data, colWidths=[120, doc.width - 120])
    file_table.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('TEXTCOLOR', (0, 0), (0, -1), colors.HexColor('#6b7280')),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('LINEBELOW', (0, 0), (-1, -2), 0.5, colors.HexColor('#f3f4f6')),
    ]))
    story.append(file_table)
    story.append(Spacer(1, 16))
    
    # Key Findings
    findings = result.get("findings", [])
    if findings:
        story.append(Paragraph("Key Findings", heading_style))
        story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#e5e7eb')))
        story.append(Spacer(1, 8))
        
        for i, finding in enumerate(findings, 1):
            severity = finding.get("severity", "info").upper()
            description = finding.get("description", "")
            detail = finding.get("detail", "")
            
            severity_color = {
                "CRITICAL": colors.HexColor('#ef4444'),
                "WARNING": colors.HexColor('#f59e0b'),
                "INFO": colors.HexColor('#3b82f6'),
            }.get(severity, colors.grey)
            
            finding_text = f"<b>[{severity}]</b> {description}"
            if detail:
                finding_text += f"<br/><i>{detail}</i>"
            
            story.append(Paragraph(finding_text, body_style))
            story.append(Spacer(1, 4))
    
    # Suspicious Timestamps (for video)
    suspicious_frames = result.get("suspicious_frames", [])
    if suspicious_frames:
        story.append(Spacer(1, 8))
        story.append(Paragraph("Suspicious Timestamps", heading_style))
        story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#e5e7eb')))
        story.append(Spacer(1, 8))
        
        ts_data = [["Timestamp", "Score", "Risk Level"]]
        for frame in suspicious_frames[:15]:  # Limit to 15
            ts = frame.get("timestamp_fmt", f"{frame.get('timestamp', 0)}s")
            score = f"{frame.get('score', 0) * 100:.0f}%"
            level = frame.get("risk_level", "N/A")
            ts_data.append([ts, score, level])
        
        ts_table = Table(ts_data, colWidths=[100, 80, 100])
        ts_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#f8fafc')),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('ALIGN', (1, 0), (1, -1), 'CENTER'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('LINEBELOW', (0, 0), (-1, -1), 0.5, colors.HexColor('#f3f4f6')),
        ]))
        story.append(ts_table)
    
    # Face Analysis Details
    face_analyses = result.get("face_analyses", [])
    if face_analyses:
        story.append(Spacer(1, 8))
        story.append(Paragraph("Face Analysis Details", heading_style))
        story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#e5e7eb')))
        story.append(Spacer(1, 8))
        
        face_data = [["Face #", "Fake Prob", "Real Prob", "Confidence", "Risk"]]
        for i, face in enumerate(face_analyses[:10]):  # Limit to 10
            face_data.append([
                str(i + 1),
                f"{face.get('fake_prob', 0) * 100:.1f}%",
                f"{face.get('real_prob', 0) * 100:.1f}%",
                f"{face.get('confidence', 0) * 100:.1f}%",
                face.get("risk_level", "N/A"),
            ])
        
        face_table = Table(face_data, colWidths=[50, 75, 75, 80, 70])
        face_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#f8fafc')),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('LINEBELOW', (0, 0), (-1, -1), 0.5, colors.HexColor('#f3f4f6')),
        ]))
        story.append(face_table)
    
    # Conclusion
    story.append(Spacer(1, 16))
    story.append(Paragraph("Conclusion", heading_style))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#e5e7eb')))
    story.append(Spacer(1, 8))
    
    message = result.get("message", "Analysis complete.")
    story.append(Paragraph(f"<i>\"{message}\"</i>", body_style))
    
    # Disclaimer
    story.append(Spacer(1, 24))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#e5e7eb')))
    story.append(Spacer(1, 8))
    
    disclaimer_style = ParagraphStyle(
        'Disclaimer',
        parent=styles['Normal'],
        fontSize=8,
        textColor=colors.HexColor('#9ca3af'),
        leading=11,
    )
    
    story.append(Paragraph(
        "<b>Disclaimer:</b> This report is generated by an AI system and is intended for informational "
        "purposes only. The risk scores and assessments are probabilistic predictions and should not be "
        "considered definitive proof of manipulation or authenticity. Professional forensic analysis "
        "is recommended for legal or official purposes.",
        disclaimer_style
    ))
    
    # Build PDF
    doc.build(story)
    
    logger.info("Generated PDF report: %s", pdf_path)
    return pdf_path
