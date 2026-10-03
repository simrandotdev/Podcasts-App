"""On Air API: podcast search and trending podcasts for the On Air apps, backed by Podcast Index."""

from contextlib import asynccontextmanager
from typing import Annotated, Literal

import httpx
from fastapi import APIRouter, Depends, FastAPI, HTTPException, Query, Request
from fastapi.responses import JSONResponse

from .config import Settings, get_settings
from .podcast_index import PodcastIndexClient, PodcastIndexError
from .schemas import SearchResponse, search_response


@asynccontextmanager
async def lifespan(app: FastAPI):
    # One connection pool for every request to Podcast Index.
    async with httpx.AsyncClient(timeout=get_settings().request_timeout_seconds) as http:
        app.state.http = http
        yield


app = FastAPI(
    title="On Air API",
    version="1.0.0",
    summary="Podcast search for the On Air apps, backed by Podcast Index.",
    lifespan=lifespan,
)


def get_podcast_index(request: Request, settings: Annotated[Settings, Depends(get_settings)]) -> PodcastIndexClient:
    return PodcastIndexClient(request.app.state.http, settings)


PodcastIndex = Annotated[PodcastIndexClient, Depends(get_podcast_index)]


@app.exception_handler(PodcastIndexError)
async def podcast_index_error(request: Request, error: PodcastIndexError) -> JSONResponse:
    return JSONResponse(status_code=error.status_code, content={"detail": error.message})


@app.get("/health", tags=["status"])
async def health() -> dict[str, str]:
    """Reports that the server is running. It doesn't call Podcast Index."""
    return {"status": "ok"}


v1 = APIRouter(prefix="/v1", tags=["podcasts"])


@v1.get("/search", response_model=SearchResponse)
async def search(
    podcast_index: PodcastIndex,
    term: Annotated[str, Query(min_length=1, max_length=200,
                               description="Words to match against podcast titles, authors and owners.")],
    limit: Annotated[int, Query(ge=1, le=200, description="The most results to return.")] = 50,
    media: Annotated[Literal["podcast"], Query(description="Accepted for iTunes compatibility.")] = "podcast",
    entity: Annotated[Literal["podcast"], Query(description="Accepted for iTunes compatibility.")] = "podcast",
) -> SearchResponse:
    """Searches podcasts by title, author and owner.

    Replaces `https://itunes.apple.com/search?media=podcast&entity=podcast`. It takes the same `term` and
    `limit` parameters and returns the same response shape, so a client only needs a new base URL.
    """
    term = term.strip()
    if not term:
        raise HTTPException(status_code=422, detail="The search term can't be blank.")
    return search_response(await podcast_index.search_by_term(term, limit))


@v1.get("/podcasts/trending", response_model=SearchResponse)
async def trending(
    podcast_index: PodcastIndex,
    limit: Annotated[int, Query(ge=1, le=200, description="The most results to return.")] = 50,
    lang: Annotated[str | None, Query(max_length=16, description='A language code, such as "en".')] = None,
    category: Annotated[str | None, Query(max_length=200,
                                          description="Category names or IDs, separated by commas.")] = None,
) -> SearchResponse:
    """Lists podcasts that are trending now, in the same shape as search results."""
    return search_response(await podcast_index.trending(limit, lang, category))


app.include_router(v1)
