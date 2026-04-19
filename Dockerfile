# Builder stage: use system Python, install uv and build the project environment
FROM python:3.14-slim AS builder

# Copy uv binary from Astral's published image (pin a version for reproducibility)
COPY --from=ghcr.io/astral-sh/uv:0.11.7 /uv /uvx /bin/

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_PYTHON_CACHE_DIR=/root/.cache/uv/python
ENV UV_LINK_MODE=copy

WORKDIR /app

# Install minimal system build deps required by some wheels
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*


# Copy minimal project metadata first so dependency layer can be cached
COPY pyproject.toml uv.lock ./

# Pre-install deps (no project yet) for cache efficiency
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project --all-groups

# Copy source, install project + all groups (train group available)
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable --all-groups

# Train with sklearn present
RUN uv run python train.py --out /app/models

# Strip train group: uv removes those packages in place
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable


# Final runtime image: small, non-root
FROM python:3.14-slim

# Create non-root user
RUN groupadd --system app && useradd --system --create-home --gid app app

# Copy uv binary for runtime commands
#COPY --from=ghcr.io/astral-sh/uv:0.11.7 /uv /uvx /bin/

# Copy only the minimal runtime virtual environment from the builder (no build deps)
COPY --chown=app:app --from=builder /app/.venv /app/.venv
COPY --chown=app:app --from=builder /app/models /app/models
COPY --chown=app:app --from=builder /app/app.py /app/

WORKDIR /app

# Put the venv's bin directory first in PATH
ENV PATH="/app/.venv/bin:$PATH"

# Switch to non-root user
USER app

EXPOSE 8000

# Run via uv to ensure the project's environment is used
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
