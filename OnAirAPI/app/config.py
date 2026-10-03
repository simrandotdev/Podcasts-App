"""Settings, read from environment variables or from `OnAirAPI/.env`."""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

ENV_FILE = Path(__file__).resolve().parent.parent / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=ENV_FILE, env_file_encoding="utf-8", extra="ignore")

    podcastindex_api_key: str = ""
    podcastindex_api_secret: str = ""
    podcastindex_base_url: str = "https://api.podcastindex.org/api/1.0"
    # Podcast Index asks every caller to identify itself.
    user_agent: str = "OnAirAPI/1.0"
    request_timeout_seconds: float = 15.0

    @property
    def has_credentials(self) -> bool:
        return bool(self.podcastindex_api_key and self.podcastindex_api_secret)


@lru_cache
def get_settings() -> Settings:
    return Settings()
