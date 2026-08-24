# 13. Data Architecture (as-built)

V1 metadata is **two SQLite tables** plus SharedPreferences plus the filesystem. Do not recreate the original multi-database design (search index DB, cache DB, encrypted vault DB) as separate engines.
