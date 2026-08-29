# DEEPTRACE — Flutter UI/UX Prototype

## AI Deepfake Investigator

> "Don't just detect the fake. Investigate the evidence."

---

## Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- Dart SDK (included with Flutter)

### Quick Start

1. Navigate to this directory:
   ```bash
   cd flutter_app
   ```

2. Create platform directories (if not present):
   ```bash
   flutter create . --project-name deeptrace
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

   Or for web:
   ```bash
   flutter run -d chrome
   ```

---

## Project Structure

```
lib/
├── main.dart                          # Entry point
├── app.dart                           # MaterialApp + routing
├── core/
│   ├── theme/
│   │   └── app_theme.dart             # Centralized dark theme
│   └── constants/
│       └── app_constants.dart         # Brand + static data
├── models/
│   └── investigation.dart             # Data model + mock data
├── screens/
│   ├── splash/splash_screen.dart      # Splash screen
│   ├── dashboard/dashboard_screen.dart # Home / Dashboard
│   ├── upload/upload_screen.dart       # Upload evidence
│   ├── analysis/analysis_screen.dart   # Analysis with animation
│   ├── results/results_screen.dart     # Investigation results
│   ├── evidence/evidence_screen.dart   # Evidence / frames viewer
│   └── report/report_screen.dart       # Forensic report
└── widgets/
    ├── primary_button.dart             # Reusable button
    ├── evidence_card.dart              # Recent investigation card
    ├── risk_score_card.dart            # Risk score display
    ├── analysis_metric_card.dart       # Analysis metric with bar
    ├── finding_card.dart               # Finding item
    └── timeline.dart                   # Investigation timeline
```

---

## Navigation Flow

```
Splash → Dashboard → Upload Evidence → Analysis → Results → Evidence Analysis
                                   ↘ (Demo)   ↗         → Forensic Report
```

---

## Screens

| # | Screen | Description |
|---|--------|-------------|
| 1 | **Splash** | Branded intro with forensic scan icon |
| 2 | **Dashboard** | Hero section, recent investigations, how-it-works |
| 3 | **Upload** | Media type selection + drag/drop area + demo option |
| 4 | **Analysis** | Scanning animation, progress bar, step checklist |
| 5 | **Results** | Risk score, assessment, analysis breakdown |
| 6 | **Evidence** | Media preview, heatmap, timeline, frame thumbnails |
| 7 | **Report** | Structured forensic report, findings, conclusion |

---

## Design System

- **Theme**: Dark cybersecurity aesthetic
- **Fonts**: Inter (UI) + JetBrains Mono (monospace)
- **Colors**: Deep navy background, blue primary, red/amber/green risk indicators
- **Cards**: Subtle borders, dark surfaces, clean hierarchy

---

## Demo Flow

For hackathon presentations, use the **"Try Demo Investigation"** button on the Dashboard to go through the complete flow without needing real files.
