---
name: docs
description: Fetch up-to-date library documentation via Context7 CLI. Use when you need API docs, setup steps, or code examples for React Native, React, React Navigation, Reanimated, Gesture Handler, or other project dependencies.
---

# Context7 docs (CLI)

Token-efficient alternative to the Context7 MCP server. Uses `npx ctx7` — no extra MCP tools.

## Workflow

1. **Resolve library** (when ID is unknown):

   ```bash
   npx ctx7 library "<library name>" "<what you need to do>"
   ```

2. **Query docs** with the returned library ID (always starts with `/`):

   ```bash
   npx ctx7 docs "<libraryId>" "<specific question>"
   ```

3. Use only the snippets relevant to the task. Do not paste entire doc dumps into the chat.

## Examples

```bash
npx ctx7 library "react-native" "background download task"
npx ctx7 docs "/facebook/react-native" "How to run background tasks on Android"

npx ctx7 library "react-navigation" "native stack navigator screen options"
npx ctx7 docs "/react-navigation/react-navigation" "How to configure header back button in native stack"
```

## Authentication

If rate-limited, run once (Personal environment only):

```bash
npx ctx7 login
```

Or set `CONTEXT7_API_KEY` in your shell profile (never commit keys).

## Version-specific docs

Include the version in the query when it matters, e.g. "React Native 0.81 safe area context".
