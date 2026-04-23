# Canva Graphics Plugin

This repo-local Codex plugin is a scaffold for a Canva-centered asset workflow for the FAST app.

Current state:
- It provides a plugin manifest and a reusable skill for Canva export guidance.
- It does not yet include a live Canva API or browser integration.

What it is useful for now:
- Standardizing quick link graphic exports
- Standardizing FAST homepage hero image exports
- Documenting where each exported asset belongs in the Flutter app

Recommended next step:
- Use the included skill to keep exports consistent, then replace the asset files under `fast/assets/images/`.
- If you want a true Canva integration later, we can extend this plugin with auth, MCP/app wiring, or a browser-assisted workflow.
