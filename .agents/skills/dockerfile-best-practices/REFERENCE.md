# Dockerfile Best Practices — Reference

Detailed rationale for each practice in SKILL.md.

## Pin Base Image Versions

```dockerfile
# Bad
FROM alpine:latest

# Good
FROM alpine:3.19
```

`:latest` is a moving target. Builds become non-reproducible and can break without code changes. Pin to a specific minor version. Use Dependabot or Renovate to automate version bumps.

## Layer Ordering and Caching

Docker caches layers sequentially. If layer N changes, layers N+1 through end are rebuilt. Order instructions from least to most frequently changed:

```dockerfile
# 1. Base image + system deps (rarely changes)
FROM alpine:3.19
RUN apk add --no-cache python3 py3-pip

# 2. App dependencies (changes when deps change)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. Source code (changes most often)
COPY src/ /app/src/
```

Copying `requirements.txt` separately from source means dependency layers are cached across source-only changes.

## Multi-Stage Builds

Separate concerns into stages to minimize final image size and attack surface:

| Stage       | Purpose                        | Carries forward |
|-------------|--------------------------------|-----------------|
| `builder`   | Install system + app deps      | Runtime deps    |
| `test`      | Run tests with dev deps        | Nothing         |
| `artifact`  | Final minimal runtime image    | App code only   |

Test dependencies (pytest, linters) never appear in the production image. Build tools (gcc, make) stay in the builder.

```dockerfile
FROM alpine:3.19 AS builder
# ... install deps, copy source

FROM builder AS test
# ... install dev deps, run tests

FROM builder AS artifact
# ... set up non-root user, entrypoint
```

## Consolidate RUN Commands

Each `RUN` creates a layer. Consolidate related commands to reduce image size:

```dockerfile
# Bad — 3 layers, apk cache persists in layer 1
RUN apk update
RUN apk add python3
RUN apk add git

# Good — 1 layer, no cache residue
RUN apk update && apk add --no-cache python3 git
```

Use `&&` to chain and `\` for line breaks in long commands.

## No-Cache Package Installs

Package manager caches waste space in layers:

```dockerfile
# pip
RUN pip install --no-cache-dir -r requirements.txt

# apk
RUN apk add --no-cache python3 git

# apt
RUN apt-get update && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*
```

## Non-Root User

Running as root inside containers is a security risk. Always create and switch to a non-root user in the final stage:

```dockerfile
RUN addgroup --system nonroot && \
    adduser --system --ingroup nonroot nonroot
USER nonroot
```

Place `USER` after all `RUN` commands that need root (installing packages, creating directories) but before `ENTRYPOINT`/`CMD`.

## ENTRYPOINT vs CMD

- `ENTRYPOINT` — the executable (hard to override)
- `CMD` — default arguments (easy to override at `docker run`)

```dockerfile
ENTRYPOINT ["python", "/app/main.py"]
CMD ["--help"]
```

This lets users run `docker run myimage --verbose` to override just the arguments. Always use exec form (`["..."]`) over shell form to ensure proper signal handling.

## HEALTHCHECK

For long-running services, define a health check so orchestrators know when the container is ready:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1
```

Not needed for CLI tools or batch jobs.

## .dockerignore

A missing or incomplete `.dockerignore` sends unnecessary files to the build context, slowing builds and risking secret leaks.

Must exclude:
- `.git/` — large, not needed at runtime
- `__pycache__/`, `*.pyc`, `node_modules/` — build artifacts
- `.env`, `*.secret`, `credentials.*` — secrets
- `coverage.xml`, test reports — CI artifacts
- IDE config (`.vscode/`, `.idea/`)

## Docker Compose Best Practices

### Pin Versions

```yaml
# Bad
image: postgres

# Good
image: postgres:16.2-alpine
```

### Resource Limits

```yaml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
```

### Read-Only Filesystem

```yaml
services:
  api:
    read_only: true
    tmpfs:
      - /tmp
```

### Health Checks

```yaml
services:
  db:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```

### Secrets

Never put secrets in `environment:` blocks in committed files. Use Docker secrets, `.env` files (gitignored), or external secret managers.

## Security Considerations

- Never use `ARG` for secrets — they persist in image history (`docker history`)
- Never `COPY` secret files — use multi-stage builds or BuildKit secret mounts: `RUN --mount=type=secret,id=mysecret`
- Scan images with Trivy or similar before deploying
- Use `docker scout` or `snyk container test` for vulnerability scanning
