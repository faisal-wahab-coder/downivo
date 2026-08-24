# ADR-004: Clean Architecture Layers

**Status:** Accepted

Presentation → Application → Domain → Data. Dependencies downward only.

UI never opens SQLite or writes files directly. Feature packages export barrels.

`platform_android` was planned; V1 uses conditional imports inside `storage` / `database` / `app_core` instead. Do not require a separate platform package.
