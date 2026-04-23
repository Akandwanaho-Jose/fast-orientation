---
name: canva-assets
description: Use this skill when preparing Canva graphics for the FAST app so exported files stay portable, lightweight, and consistent across quick links, homepage hero art, and leadership imagery.
---

# Canva Assets

Use this workflow when you want polished Canva graphics that drop cleanly into the FAST Flutter app.

## Quick Link Graphics

- Design each graphic in Canva on a square canvas.
- Preferred canvas sizes:
  - `1024x1024` for master design
  - `512x512` minimum for export
- Export format: `PNG`
- Use transparent background when possible.
- Keep the symbol large and centered with generous padding.
- Avoid small text inside the icon. Use shape, color, and symbol instead.

Project file targets:
- `fast/assets/images/quick_links/sims_student_portal.png`
- `fast/assets/images/quick_links/must_student_advisor.png`
- `fast/assets/images/quick_links/must_elearning.png`
- `fast/assets/images/quick_links/must_timetable.png`

## Homepage Hero Graphic

- Use a wide landscape Canva layout.
- Preferred canvas sizes:
  - `1600x900`
  - `1920x1080`
- Export format: `JPG` or `PNG`
- Choose a clean FAST building image with space for headline text.
- Avoid placing important visual detail at the very edges because the app crops responsively.
- Keep the composition calm, modern, and institutional rather than poster-like.

Project file target:
- `fast/assets/images/home/fast_building_hero.jpg`

## Leadership Photos

- Use clear portrait photos with clean background separation.
- Prefer vertical crops with face and shoulders visible.
- Export size target:
  - `1200px` on the shortest side is enough for crisp in-app display
- Avoid heavy Canva filters that make real people look artificial.

## Portable Design Rules

- Keep file names stable so the app does not need code changes.
- Prefer compressed images that still look sharp on mobile.
- Use consistent visual language:
  - MUST blue and green
  - minimal text
  - clean icon silhouettes
  - high contrast

## Recommended FAST Workflow

1. Design in Canva using one consistent template family.
2. Export into the exact asset filenames already used by the app.
3. Replace the files in `fast/assets/images/`.
4. Rebuild or hot restart the Flutter app to review the result.
5. Adjust cropping if text or faces feel cramped on smaller screens.
