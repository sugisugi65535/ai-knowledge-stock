from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.config import get_settings
from app.database import Base, engine
import app.models  # noqa: F401

settings = get_settings()
origins = [origin.strip() for origin in settings["CORS_ORIGINS"].split(",") if origin.strip()]
if not origins:
    raise RuntimeError("必須環境変数 CORS_ORIGINS が空です")

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)


@app.get("/api/healthz")
def healthz() -> dict[str, str]:
    try:
        with engine.connect() as connection:
            connection.execute(text("select 1;"))
        return {"healthz": "success"}
    except Exception:
        return {"healthz": "fail"}
