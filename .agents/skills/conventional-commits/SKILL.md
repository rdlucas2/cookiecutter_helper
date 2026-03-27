---
name: conventional-commits
description: Format git commit messages following the Conventional Commits specification. Use when user wants to commit, asks for a commit message, mentions "conventional commits", or wants standardized commit messages.
---

# Conventional Commits

Format all commit messages per the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification.

## Format

```
<type>(<optional scope>): <description>

<optional body>

<optional footer(s)>
```

## Types

| Type       | When to use                                      |
|------------|--------------------------------------------------|
| `feat`     | A new feature                                    |
| `fix`      | A bug fix                                        |
| `docs`     | Documentation only changes                       |
| `style`    | Formatting, missing semicolons, whitespace, etc. |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf`     | Performance improvement                          |
| `test`     | Adding or correcting tests                       |
| `build`    | Changes to build system or external dependencies |
| `ci`       | CI configuration files and scripts               |
| `chore`    | Maintenance tasks that don't modify src or tests |

## Rules

1. **Description**: lowercase, imperative mood, no period at end, max 72 chars for the first line
2. **Scope**: optional, lowercase, in parentheses after type — e.g. `feat(auth): add login endpoint`
3. **Body**: wrap at 72 chars, explain *what* and *why* (not *how*), separated from description by a blank line
4. **Breaking changes**: use a `BREAKING CHANGE:` footer (never the `!` suffix syntax)
   ```
   feat(api): change user response shape

   BREAKING CHANGE: user endpoint now returns nested profile object
   ```
5. **Multiple footers** are allowed — each on its own line using `token: value` or `token #value` format

## Examples

```
feat(parser): add support for arrays in config files
```

```
fix: prevent race condition in database connection pool

The connection pool was not properly synchronized when multiple
requests arrived simultaneously during startup.

Reviewed-by: Z
Refs: #123
```

```
refactor: extract validation logic into shared utility

BREAKING CHANGE: validate() now returns a Result object instead of throwing
```

## Validation

A commit-msg hook script is available at `scripts/validate-commit-msg.sh`.
Install it as a git hook:

```bash
cp .agents/skills/conventional-commits/scripts/validate-commit-msg.sh .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg
```

<!-- PROJECT-SPECIFIC: Remove or modify this section per project -->

## Project-Specific Scopes

Suggested scopes for this project (optional):

| Scope      | When to use                          |
|------------|--------------------------------------|
| `docker`   | Dockerfile or docker-compose changes |
| `generator`| Changes to repo_generator.py         |
| `sonar`    | SonarQube configuration changes      |
| `deps`     | Dependency updates (requirements.txt)|

<!-- END PROJECT-SPECIFIC -->
