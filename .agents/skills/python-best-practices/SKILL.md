---
name: python-best-practices
description: Enforce Python code quality, packaging, typing, and dependency management best practices. Use when user writes, reviews, or refactors Python code, creates Python packages, manages dependencies, or mentions Python style, linting, or type hints.
---

# Python Best Practices

Target: Python 3.13+ (latest stable). Defer test strategy to the **tdd** skill.

## Quick Start Checklist

When writing or reviewing Python code, verify:

- [ ] Type hints on all function signatures (params + return)
- [ ] `dataclass` or `NamedTuple` over plain dicts for structured data
- [ ] f-strings over `.format()` or `%`
- [ ] `pathlib.Path` over `os.path` for file operations
- [ ] `subprocess.run()` with explicit args list (never shell=True with user input)
- [ ] Context managers (`with`) for all resource handling
- [ ] No mutable default arguments (`def f(x=[])` → `def f(x=None)`)
- [ ] Specific exceptions caught (never bare `except:`)
- [ ] Imports sorted: stdlib → third-party → local (one blank line between groups)
- [ ] No unused imports or variables

## Workflows

### Writing New Code

1. Add type hints to all signatures — use `|` union syntax (`str | None` not `Optional[str]`)
2. Use `dataclass` or `NamedTuple` for any struct with 3+ fields
3. Prefer `match`/`case` over elif chains for structural pattern matching
4. Use walrus operator (`:=`) when it improves readability in while loops or comprehensions
5. Use `itertools`, `functools`, and comprehensions over manual loops where clearer
6. Prefer `enum.Enum` or `enum.StrEnum` for fixed sets of values

### Reviewing Existing Code

1. Run the lint script: `scripts/lint-python.sh <path>`
2. Check each rule in the checklist above
3. Flag any `# type: ignore` without a specific error code
4. Flag `subprocess` calls using `shell=True`

### Packaging

1. Use `pyproject.toml` as the single source of project metadata (PEP 621)
2. Pin direct dependencies in `requirements.txt` with `==`; use ranges in `pyproject.toml`
3. Separate runtime and dev dependencies (`requirements.txt` vs `requirements-dev.txt`, or `[project.optional-dependencies]` in pyproject.toml)
4. Include `py.typed` marker for typed packages

### Virtual Environments

1. Always develop inside a venv: `python -m venv .venv && source .venv/bin/activate`
2. Add `.venv/` to `.gitignore`
3. Regenerate with `pip install -r requirements.txt` — never commit the venv

## Validation

```bash
.agents/skills/python-best-practices/scripts/lint-python.sh [path]
```

See [REFERENCE.md](REFERENCE.md) for detailed rationale and 3.13 features.

<!-- PROJECT-SPECIFIC: Remove or modify this section per project -->

## Project-Specific Conventions

- **Structured data**: `namedtuple` via `collections.namedtuple` (existing pattern — prefer `typing.NamedTuple` or `dataclass` for new code)
- **CLI parsing**: `argparse` — keep parser setup in `if __name__ == '__main__'` block
- **Subprocesses**: `subprocess.run()` with explicit arg lists, no `shell=True`
- **Dependencies**: split `requirements.txt` (runtime) / `requirements-dev.txt` (test)
- **Test framework**: `unittest` with `unittest.mock` (see tdd skill for test strategy)

<!-- END PROJECT-SPECIFIC -->
