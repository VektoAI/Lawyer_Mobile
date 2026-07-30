"""Production entry: API-only when MUNSHI_SERVE_UI=0 (mobile Render deploy)."""
from app.factory import create_app

app = create_app()
