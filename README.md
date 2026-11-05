# GenshinQuizDev / MoeLink

This repository coordinates the GenshinQuiz and MoeLink applications and their Docker deployment. The applications live in separate repositories under `repos/`.

本仓库用于统一管理 GenshinQuiz、MoeLink 及其 Docker 部署配置。各应用代码位于 `repos/` 下的独立 Git 仓库。

## Repositories

| Directory | Project |
|---|---|
| `repos/frontend` | GenshinQuiz React/Vite frontend |
| `repos/backend` | GenshinQuiz Go API |
| `repos/MoeLink` | MoeLink Vue/Vite frontend |
| `repos/node-api` | MoeLink Node.js API and maj-server |
| `repos/moelink-gateway` | Reverse proxy, monitoring, dashboard, and release guardian |
| `repos/AlphaSoul_Js` | AlphaSoul Mahjong tool |

`vue-home` and `liantui-hp` are not part of the current Compose project.

## Deployment

The default [docker-compose.yml](./docker-compose.yml) builds and serves both frontends as static assets with Nginx. It starts the database, APIs, gateway, and maj-server as well.

### First-time setup

1. Clone this repository and enter its directory.
2. Run `./setup.sh` to clone/update the application repositories and initialize submodules. The script uses SSH for GitHub access and updates each repository's `main` branch (falling back to `master` if `main` does not exist).
3. If `.env` does not exist, the script copies [.env.example](./.env.example) to `.env`. Edit the generated file before starting services:
   - Replace `JWT_SECRET`, `POSTGRES_PASSWORD`, and `GATEWAY_ADMIN_TOKEN` with private values.
   - `JWT_SECRET` is only used by `auth-service` for OAuth state tokens. Login tokens are signed with an ES256 key that `auth-service` generates into the `auth_keys` volume; other services verify them through `AUTH_JWKS_URL`. In production also set `SESSION_COOKIE_DOMAIN=.moelink.site`.
   - Set `BOOTSTRAP_ADMIN_EMAIL` to your email. If no admin exists yet, `auth-service` will create the account with `BOOTSTRAP_ADMIN_PASSWORD` (or promote an existing verified account) on first start. If the account exists but is unverified, the password must match or set `BOOTSTRAP_ADMIN_RESET_PASSWORD=true`. Remove the password from `.env` after the first successful login.
   - Set `GATEWAY_ADMIN_EMAILS` and `MIAO_OWNER_EMAILS` to your email. Email whitelists are stable across database rebuilds; `GATEWAY_ADMIN_USER_IDS` / `MIAO_OWNER_USER_IDS` remain only for compatibility.

   To add an admin later without changing startup env, run inside the auth-service container:

   ```bash
   docker compose exec auth-service go run ./cmd/seed-admin -email you@example.com
   ```

   If the account does not exist yet, add `-password '...' -nickname '...'`. Existing accounts are only promoted and their password is not changed; add `-reset-password` only if you explicitly want to overwrite it.
   - On Synology or another host where port 5432 is occupied, set `POSTGRES_HOST_PORT=5433` (or another free port). This changes only the host mapping; containers continue to use `postgres:5432`.
4. Start the project:

   ```bash
   docker compose up -d --build
   ```

On Synology Container Manager, create a Project from this directory and its `docker-compose.yml`. Include the complete `repos/` and `config/` directories and the edited `.env`.

To generate only `.env` without updating repositories or starting services, run `./setup.sh --env`. It fills `change-me` placeholders (JWT, database password, admin tokens, session secret) with random values and never overwrites an existing `.env`. `./setup.sh --env --force` regenerates it from `.env.example`: the old file is backed up as `.env.bak.<timestamp>`, and existing values (and any extra variables) are preserved. Fill in the optional keys (OAuth, Sentry, Resend, Azure) afterwards.

Alternatively, `./setup.sh --up` updates repositories and starts Compose after the repositories are clean. On Synology, where Docker requires elevated permissions, use `./setup.sh --up --sudo`. If the script creates `.env` during that run, it stops so that you can edit the secrets before retrying.

### Google and GitHub sign-in

`auth-service` (Go) handles OAuth for both applications. Configure Google and GitHub OAuth credentials in the root `.env`:

- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`
- `GITHUB_OAUTH_CLIENT_ID` / `GITHUB_OAUTH_CLIENT_SECRET`
- `OAUTH_CALLBACK_BASE_URL=https://api.moelink.site`
- `OAUTH_COOKIE_DOMAIN=.moelink.site` so the state cookie is shared across the frontend and API subdomains

Register these exact callback URLs with the providers:

```text
https://api.moelink.site/auth/google/callback
https://api.moelink.site/auth/github/callback
```

`OAUTH_ALLOWED_REDIRECT_ORIGINS` is an exact allowlist for the final frontend redirect. The OAuth flow only accepts a verified provider email; it links that email to an existing unified account or creates a new one. Provider access tokens are not stored. Use separate provider applications and credentials for local testing; set `OAUTH_CALLBACK_BASE_URL=http://localhost:8000` and leave `OAUTH_COOKIE_DOMAIN` empty for local Compose development. Restart/recreate the Go API after changing `.env`.

### Public API entry

Point `api.moelink.site` at the gateway (host port `8000`), not directly at node-api (`8020`) or the Go services (`8080` / `8081`). The gateway forwards `/auth/*` to `auth-service`, `/stock/*` to the stock worker, `/go-api/*` to the quiz API, and its `/` catch-all forwards every other path to node-api. Existing URLs such as `https://api.moelink.site/user/session` therefore keep working, while OAuth becomes available. In Cloudflare Tunnel, change the `api.moelink.site` service target from `http://localhost:8020` to `http://localhost:8000`; no path rules are required.

### Services and ports

| Service | Host port | Notes |
|---|---:|---|
| GenshinQuiz frontend | 3000 | Static site |
| GenshinQuiz API | 8080 | Go, quiz routes only |
| Auth service | 8081 | Go, `/auth/*`; bound to loopback by default |
| MoeLink frontend | 5173 | Static site |
| MoeLink gateway/dashboard | 8000 | Dashboard: `/_gateway/ui` |
| MoeLink Node API | 8020 | |
| Stock worker | 8182 (loopback) | Real stock data API (`/stock/*`) and crawl scheduler |
| maj-server | 8181 | |
| PostgreSQL | 5432 by default | Bound to loopback; configure with `POSTGRES_HOST_PORT` |

The database is not exposed to the LAN by default. Container-to-container connections use port 5432 regardless of the host port mapping.

## Local frontend development

`docker-compose.local.yml` is a complete, standalone Compose file (it does not extend `docker-compose.yml`). It starts every service and runs both Vite frontends with source mounts and hot reload:

```bash
docker compose -f docker-compose.local.yml up -d
```

Use `docker-compose.yml` for the static production-style deployment. Both files read the same root `.env`; keep service definitions in sync when changing either file. `vue-home` is not currently defined as a Compose service.

## Useful commands

```bash
docker compose ps
docker compose logs -f moe-link node-api
docker compose down
```

`docker compose down -v` also deletes named volumes, including PostgreSQL data; use it only when you intend to erase persistent data.

See [DEVELOPMENT.md](./DEVELOPMENT.md) for development workflows and [ARCHITECTURE.md](./ARCHITECTURE.md) for the system overview.
