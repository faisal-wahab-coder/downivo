# ADR-003: Feature-Based Melos Monorepo

**Status:** Accepted  
**Date:** 2026-08-15

## Decision

All application code lives under `universal_downloader/` with Melos.

```
universal_downloader/
├── apps/mobile/
├── apps/web/
└── packages/
```

`melos.yaml` lists only implemented packages (see 11.2).
