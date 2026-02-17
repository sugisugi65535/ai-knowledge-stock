import os
from urllib.parse import quote_plus


def _require_env(name: str) -> str:
    value = os.getenv(name)
    if value is None or value.strip() == "":
        raise RuntimeError(f"必須環境変数が未設定です: {name}")
    return value


def get_settings() -> dict[str, str]:
    postgres_user = _require_env("POSTGRES_USER")
    postgres_password = _require_env("POSTGRES_PASSWORD")
    postgres_db = _require_env("POSTGRES_DB")
    postgres_host = _require_env("POSTGRES_HOST")
    postgres_port = _require_env("POSTGRES_PORT")
    cors_origins = _require_env("CORS_ORIGINS")
    port = _require_env("PORT")

    encoded_password = quote_plus(postgres_password)
    database_url = (
        f"postgresql+psycopg2://{postgres_user}:{encoded_password}"
        f"@{postgres_host}:{postgres_port}/{postgres_db}"
    )

    return {
        "DATABASE_URL": database_url,
        "CORS_ORIGINS": cors_origins,
        "PORT": port,
    }
