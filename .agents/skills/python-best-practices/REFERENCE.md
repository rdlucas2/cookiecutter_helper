# Python Best Practices — Reference

Detailed rationale for each practice in SKILL.md. Targets Python 3.13+.

## Type Hints

Use modern syntax available in 3.13:

```python
# Good — 3.10+ union syntax
def fetch(url: str, timeout: int | None = None) -> dict[str, Any]:
    ...

# Good — 3.12+ type parameter syntax
def first[T](items: list[T]) -> T:
    return items[0]

# Bad — legacy
from typing import Optional, Dict, List
def fetch(url: str, timeout: Optional[int] = None) -> Dict[str, Any]:
    ...
```

- Use `str | None` not `Optional[str]`
- Use `dict[str, Any]` not `Dict[str, Any]` (lowercase generics since 3.9)
- Use PEP 695 `type` statement for type aliases: `type Vector = list[float]`
- Use PEP 695 type parameter syntax for generics: `def f[T](x: T) -> T`

## Structured Data

### NamedTuple (typed)

```python
from typing import NamedTuple

class Configuration(NamedTuple):
    project_name: str
    token: str
    overrides: dict[str, str]
    output_dir: str = "."
```

Advantages over `collections.namedtuple`: type hints, defaults, IDE support.

### Dataclass

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class Configuration:
    project_name: str
    token: str
    overrides: dict[str, str]
    output_dir: str = "."
```

Use `frozen=True` for immutability, `slots=True` for memory efficiency (3.10+). Prefer dataclass over NamedTuple when you need methods, mutability options, or post-init processing.

## Pattern Matching (3.10+)

```python
# Good — structural pattern matching
match command:
    case {"action": "create", "name": str(name)}:
        create(name)
    case {"action": "delete", "id": int(id_)}:
        delete(id_)
    case _:
        raise ValueError(f"Unknown command: {command}")

# Bad — elif chain for structural dispatch
if command.get("action") == "create":
    create(command["name"])
elif command.get("action") == "delete":
    delete(command["id"])
```

## Exception Groups (3.11+)

For concurrent operations that can raise multiple errors:

```python
try:
    async with asyncio.TaskGroup() as tg:
        tg.create_task(fetch_a())
        tg.create_task(fetch_b())
except* ValueError as eg:
    for exc in eg.exceptions:
        log(exc)
except* ConnectionError as eg:
    retry(eg.exceptions)
```

## Pathlib Over os.path

```python
# Good
from pathlib import Path

config = Path("config") / "settings.json"
if config.exists():
    data = config.read_text()

# Bad
import os
config = os.path.join("config", "settings.json")
if os.path.exists(config):
    with open(config) as f:
        data = f.read()
```

## Subprocess Safety

```python
# Good — explicit arg list, no shell
result = subprocess.run(
    ["git", "clone", url, dest],
    capture_output=True,
    text=True,
    check=True,
)

# Bad — shell=True with variable input (injection risk)
subprocess.run(f"git clone {url} {dest}", shell=True)
```

Use `check=True` to raise on non-zero exit. Use `capture_output=True` when you need stdout/stderr. Use `text=True` to get str instead of bytes.

## Enum for Fixed Values

```python
from enum import StrEnum

class CommitType(StrEnum):
    FEAT = "feat"
    FIX = "fix"
    DOCS = "docs"
    REFACTOR = "refactor"
```

`StrEnum` (3.11+) values are strings, so they work directly in f-strings and comparisons.

## Comprehensions and Itertools

```python
# Good — comprehension
squares = [x ** 2 for x in range(10) if x % 2 == 0]

# Good — itertools for complex iteration
from itertools import chain, batched
all_items = chain(list_a, list_b)
chunks = batched(items, 10)  # 3.12+

# Bad — manual accumulation
squares = []
for x in range(10):
    if x % 2 == 0:
        squares.append(x ** 2)
```

Use comprehensions when the logic fits one line cleanly. Use explicit loops when the body is complex.

## Walrus Operator

```python
# Good — avoid double call
if (match := re.search(pattern, text)) is not None:
    process(match.group())

# Good — in while loops
while (chunk := f.read(8192)):
    process(chunk)
```

Don't overuse — only when it clearly eliminates redundancy.

## Mutable Default Arguments

```python
# Bad — shared mutable default
def append_to(item, target=[]):
    target.append(item)
    return target

# Good — None sentinel
def append_to(item, target: list | None = None) -> list:
    if target is None:
        target = []
    target.append(item)
    return target
```

## Import Ordering

```python
# stdlib
import os
import sys
from pathlib import Path

# third-party
import requests
from flask import Flask

# local
from myapp.config import Settings
from myapp.utils import parse
```

One blank line between each group. Alphabetical within groups.

## pyproject.toml (PEP 621)

```toml
[project]
name = "mypackage"
version = "1.0.0"
requires-python = ">=3.13"
dependencies = [
    "requests>=2.31",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "ruff>=0.5",
    "mypy>=1.10",
]

[tool.ruff]
target-version = "py313"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]

[tool.mypy]
python_version = "3.13"
strict = true
```

## Python 3.12–3.13 Features Worth Using

| Feature | Version | Example |
|---------|---------|---------|
| Type parameter syntax | 3.12 | `def f[T](x: T) -> T` |
| `type` statement | 3.12 | `type Vector = list[float]` |
| `itertools.batched` | 3.12 | `batched(items, n)` |
| Improved f-string parsing | 3.12 | Nested quotes, backslashes in f-strings |
| Improved error messages | 3.12+ | Better tracebacks, suggestions |
| `typing.override` | 3.12 | `@override` decorator for method overrides |
| Free-threaded mode | 3.13 | `--disable-gil` experimental flag |
| Improved REPL | 3.13 | Multiline editing, color output |
