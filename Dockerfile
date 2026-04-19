# Builder stage: use system Python, install uv and build the project environment
FROM python:3.14-slim AS builder

# Copy uv binary from Astral's published image (pin a version for reproducibility)
COPY --from=ghcr.io/astral-sh/uv:0.11.7 /uv /uvx /bin/

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_NO_DEV=1
ENV UV_PYTHON_CACHE_DIR=/root/.cache/uv/python
ENV UV_LINK_MODE=copy

WORKDIR /app

# Install minimal system build deps required by some wheels
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy minimal project metadata first so dependency layer can be cached
COPY pyproject.toml uv.lock ./

# Use BuildKit cache mount for uv caches (speeds repeated builds)
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project

# Copy source, then install the project in non-editable mode so we can copy only the venv to the final image
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable

# Train tiny deterministic model at build-time (quick; <100ms here)
# This produces /app/models which is copied into the runtime image below.
RUN uv run python train.py --out /app/models


# Final runtime image: small, non-root
FROM python:3.14-slim

# Create non-root user
RUN groupadd --system app && useradd --system --create-home --gid app app

# Copy uv binary for runtime commands
COPY --from=ghcr.io/astral-sh/uv:0.11.7 /uv /uvx /bin/

# Copy only the virtual environment from the builder (no source code)
COPY --chown=app:app --from=builder /app/.venv /app/.venv
COPY --chown=app:app --from=builder /app/models /app/models

WORKDIR /app

# Put the venv's bin directory first in PATH
ENV PATH="/app/.venv/bin:$PATH"

# Switch to non-root user
USER app

EXPOSE 8000

# Run via uv to ensure the project's environment is used
CMD ["uv", "run", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
