# Supabase Edge Functions (Starter)

Functions included:
- `song_import`: queue SongSelect/Ultimate Guitar import requests
- `planning_center_pull`: pull a Planning Center plan into local domain objects

## Deploy
Use Supabase CLI from the `backend/supabase` context after project linking.

## Security
- Validate JWT and team permissions per request.
- Encrypt and rotate provider tokens.
- Respect provider licensing and API terms.
