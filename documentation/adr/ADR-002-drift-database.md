# ADR-002: Drift for SQLite Metadata

**Status:** Accepted (intent) — **not how V1 shipped**

## Context

Docs mixed SQLite, WatermelonDB, and Room.

## Decision (original)

Use Drift with sqflite on Android.

## As-built override

V1 implemented **hand-written sqflite** (`AppDatabase`, schemaVersion 4). Drift codegen never landed.

**Rebuild with sqflite**, not Drift, so the replica matches production.
