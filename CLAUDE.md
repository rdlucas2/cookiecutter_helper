# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Python CLI tool that uses a cookiecutter template to generate boilerplate code for a project, then creates/pushes to a GitHub repository. It clones a cookiecutter template, generates a project with overrides from a JSON file, then clones a target repo and pushes the generated code to it.

## Architecture

Single-module application (`repo_generator.py`) with three main functions orchestrated by `main()`:
- `get_configuration()` — parses a JSON overrides file and CLI args into a `Configuration` namedtuple
- `clone_template_repo_and_generate_code()` — clones a cookiecutter template into a temp dir and runs `cookiecutter` to generate project code
- `clone_and_push_to_github()` — clones the target repo, copies generated code into it, commits, and pushes (using PAT-authenticated URL)

Tests are in `repo_generator_test.py` using `unittest` with mocks.

## Build & Run (Docker-based)

```bash
# Build artifact image
docker build -t repo-generator .

# Build test image
docker build -t repo-generator-test . --target test

# Run tests (outputs coverage to ./coverage.xml)
docker run -it --rm -v $(pwd):/coverage repo-generator-test

# Run with custom pytest args
docker run -it --rm -v $(pwd):/coverage repo-generator-test --cov=repo_generator -v

# Run the tool
docker run -it --rm -v $(pwd)/generated_code:/app/output repo-generator \
  --template_url $TEMPLATE_URL --repo_url $REPO_URL --token $GITHUB_TOKEN \
  --json_file /app/output/overrides.json --output-dir /app/output
```

## Dockerfile Structure

Multi-stage build on Alpine:
- **builder** — base with Python, pip, git, and runtime dependencies
- **test** — extends builder with pytest/pytest-cov; entrypoint is `pytest`
- **artifact** — extends builder with non-root user; entrypoint runs `repo_generator.py`

## Key Files

- `overrides.json` — example JSON overrides for cookiecutter template variables
- `sonar-project.properties` — SonarQube config (project key: `cookiecutter_helper`, excludes `*_test.py` from coverage)
