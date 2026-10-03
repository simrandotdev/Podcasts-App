import httpx
import pytest
from fastapi.testclient import TestClient

from app.config import Settings, get_settings
from app.main import app, get_podcast_index
from app.podcast_index import PodcastIndexClient
from support import NOW, FakePodcastIndex


@pytest.fixture
def podcast_index() -> FakePodcastIndex:
    return FakePodcastIndex()


@pytest.fixture
def settings() -> Settings:
    # _env_file=None keeps a developer's real .env out of the tests.
    return Settings(_env_file=None, podcastindex_api_key="test-key", podcastindex_api_secret="test-secret")


@pytest.fixture
def client(podcast_index, settings):
    http = httpx.AsyncClient(transport=httpx.MockTransport(podcast_index))
    app.dependency_overrides[get_settings] = lambda: settings
    app.dependency_overrides[get_podcast_index] = lambda: PodcastIndexClient(http, settings, clock=lambda: NOW)
    yield TestClient(app)
    app.dependency_overrides.clear()
