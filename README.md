# Deploy and Host Funkwhale on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/funkwhale?utm_medium=integration&utm_source=button&utm_campaign=funkwhale)

[Funkwhale](https://funkwhale.audio/) is a self-hosted, federated audio platform: upload your music library, stream it from any device (web, Subsonic apps), create playlists and radios, publish podcasts and channels, and optionally federate with other Funkwhale pods over ActivityPub.

## About Hosting Funkwhale

This template runs Funkwhale as three Railway services. The main service is a combined container (Django API via gunicorn, celery worker with beat for imports and federation, and nginx serving the web frontend and media) — one container, one volume, no shared-storage juggling. PostgreSQL and Redis run as separate services. On first boot it runs migrations, collects static files, and creates your admin account from the `FUNKWHALE_ADMIN_PASSWORD` variable (username `fwadmin`). Music, media, and static files persist on the volume at `/srv/funkwhale/data`.

## Common Use Cases

- Personal music streaming server for your own library (Subsonic API compatible apps work)
- Community/label pod with user accounts, channels, and podcasts
- Federated audio publishing connected to the Fediverse

## Dependencies for Funkwhale Hosting

- All bundled: PostgreSQL 17 and Redis are provisioned by the template

### Deployment Dependencies

- [Funkwhale documentation](https://docs.funkwhale.audio/)
- [Template source on GitHub](https://github.com/nomideusz/funkwhale-railway)

### Implementation Details

**Your pod is the `funkwhale` service's Railway domain.** Log in with username `fwadmin` and the `FUNKWHALE_ADMIN_PASSWORD` variable's value (auto-generated — find it in the service's variables).

Notes and limits:

- Upload music via the web UI (Libraries) or any Subsonic-compatible client; server-side in-place import is also available under `/srv/funkwhale/data/music`.
- Media lives on the service volume; volume size is plan-dependent on Railway — check your plan's cap against your library size.
- Redis is intentionally ephemeral: a restart loses only queued-but-unstarted import/federation jobs.
- Upload body size is capped at 500 MB per request by default (`NGINX_MAX_BODY_SIZE` variable).
- Funkwhale rejects a few reserved admin usernames (`admin`, `root`, …) — that's why the default is `fwadmin`; override with `FUNKWHALE_ADMIN_USERNAME`.
- If you attach a custom domain later, update `FUNKWHALE_HOSTNAME` **before** federating — the hostname is your pod's federated identity.

## Why Deploy Funkwhale on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Funkwhale on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
