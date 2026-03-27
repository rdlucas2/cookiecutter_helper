---
name: dockerfile-best-practices
description: Enforce Dockerfile, docker-compose, and .dockerignore best practices when writing or reviewing container configurations. Use when user creates, edits, or reviews Dockerfiles, docker-compose files, .dockerignore, or mentions container images, Docker builds, or image size.
---

# Dockerfile Best Practices

## Quick Start Checklist

When writing or reviewing a Dockerfile, verify:

- [ ] Pin base image versions (never use `:latest` in production)
- [ ] Multi-stage build separates build-time from runtime dependencies
- [ ] Layers ordered by change frequency (least → most frequent)
- [ ] Each `COPY` is as specific as possible (no `COPY . .` early)
- [ ] `RUN` commands consolidated with `&&` to reduce layers
- [ ] `--no-cache-dir` on package installs (pip, apk, apt)
- [ ] Non-root `USER` set before `ENTRYPOINT`/`CMD`
- [ ] `.dockerignore` excludes build artifacts, VCS, secrets
- [ ] `HEALTHCHECK` defined for long-running services
- [ ] No secrets in build args, env vars, or layers

## Workflows

### Writing a New Dockerfile

1. Choose a minimal base image (Alpine, distroless, slim variants)
2. Set `WORKDIR` early
3. Copy dependency manifests first, install, then copy source (layer caching)
4. Use multi-stage builds: separate `builder`, `test`, and `artifact`/`runtime` stages
5. Create and switch to a non-root user in the final stage
6. Set `ENTRYPOINT` for the executable, `CMD` for default arguments

### Reviewing a Dockerfile

1. Run the lint script: `scripts/lint-dockerfile.sh <path>`
2. Check each rule in the checklist above
3. Look for secrets leaked in `ENV`, `ARG`, `COPY`, or `RUN` commands
4. Verify `.dockerignore` exists and excludes sensitive/unnecessary files

### Docker Compose

1. Pin image versions in `image:` directives
2. Use named volumes over bind mounts for persistent data
3. Set `restart` policies, resource limits, and `read_only: true` where possible
4. Define `healthcheck` for services that accept connections
5. Use `.env` files for configuration, never inline secrets

### .dockerignore

Always exclude: `.git/`, `__pycache__/`, `*.pyc`, `node_modules/`, `.env`, `*.secret`, build output, test reports, IDE config.

## Validation

Lint a Dockerfile with hadolint (via Docker — no local install needed):

```bash
.agents/skills/dockerfile-best-practices/scripts/lint-dockerfile.sh Dockerfile
```

See [REFERENCE.md](REFERENCE.md) for detailed rationale behind each practice.

<!-- PROJECT-SPECIFIC: Remove or modify this section per project -->

## Project-Specific Conventions

- **Base image**: Alpine (`alpine`) — use `apk` for packages
- **Multi-stage naming**: `builder` (base + deps), `test` (extends builder), `artifact` (final runtime)
- **Non-root user**: `nonroot:nonroot` created via `addgroup --system` / `adduser --system`
- **Python deps**: split `requirements.txt` (runtime) and `requirements-dev.txt` (test-only)
- **Test stage entrypoint**: `pytest` with coverage args in `CMD`

<!-- END PROJECT-SPECIFIC -->
