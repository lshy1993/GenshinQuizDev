# System Architecture / 系统架构

This repository is the deployment workspace for several independently versioned applications. The root Compose project connects their containers on one private Docker network.

本仓库是多个独立版本管理应用的部署工作区。根目录的 Compose 项目将各容器连接到同一个内部 Docker 网络。

## Services

| Compose service | Application | Responsibility |
|---|---|---|
| `genshinquiz-frontend` | React + Vite, served by Nginx | GenshinQuiz user interface |
| `genshinquiz-backend` | Go + Chi | GenshinQuiz API (quiz routes only; no `/auth/*`) |
| `auth-service` | Go + Chi | Unified authentication: users, credentials, OAuth, JWT |
| `moe-link` | Vue + Vite, served by Nginx | MoeLink user interface |
| `node-api` | Node.js + Express + PostgreSQL | MoeLink API, forum, shop, wallet, and unified-user integration |
| `stock-worker` | Node.js | Real stock data API (`/stock/*`) and crawl scheduler, independent of `node-api` restarts |
| `maj-server` | Node.js | Mahjong service |
| `moelink-gateway` | Node.js | API reverse proxy, health monitoring, statistics, dashboard, and release status |
| `postgres` | PostgreSQL | Persistent storage for the applications |

The default Compose file builds both web frontends as static assets served by Nginx. `docker-compose.local.yml` is a standalone, complete Compose file for local development (it does not extend the default file); it runs the same services but serves these two frontends from Vite development servers with source mounts and hot reload.

## Network and access

Containers connect to each other using Compose service names, for example:

- `node-api:8020`
- `genshinquiz-backend:8080`
- `auth-service:8081`
- `postgres:5432`

The public host ports are declared in `docker-compose.yml`. PostgreSQL is bound to the host loopback address only, with a default host port of 5432. Set `POSTGRES_HOST_PORT` in the root `.env` to use another host port; the internal container port remains 5432.

The gateway listens on port 8000. It exposes `/auth`, `/stock`, `/node-api`, and `/go-api` proxy prefixes, monitors configured services, and serves its dashboard at `/_gateway/ui`.

`api.moelink.site` should point at the gateway, not directly at node-api. The gateway sends `/auth/*` to `auth-service`, `/go-api/*` to the quiz API, and its `/` catch-all to node-api. This keeps the public API origin stable while giving authentication and quiz routes a single entry point.

## Databases and migrations

PostgreSQL initializes the `moelink` database through `POSTGRES_DB`. The root `config/init.sql` additionally creates `genshinquiz` and `majstatus` when PostgreSQL initializes a new data directory.

- The Go backend applies its Goose migrations during container startup.
- The Node API applies Knex migrations to the `moelink` database before starting.
- The Node API also connects to `genshinquiz` for unified-user reads and to `majstatus` for Mahjong data.
- `config/init.sql` is run only when the PostgreSQL data directory is first initialized. Existing volumes are not changed by edits to that file.

Persistent database files are stored in the `postgres_data` named volume. Removing the Compose project does not remove named volumes unless `-v` is specified.

## Unified authentication

`auth-service` is the identity authority. It serves `/auth/*`, owns the `users` / `user_credentials` / OAuth / session tables, and is the only service holding a signing key. Access tokens are ES256 JWTs (15 minutes by default); `genshinquiz-backend`, `node-api`, and the gateway only fetch the public key from `AUTH_JWKS_URL` (`/auth/.well-known/jwks.json`) and verify tokens locally. No signing secret is shared with them.

- `genshinquiz-backend` runs with `SERVICE_MODE=quiz`; `/auth/*` returns 404 there.
- `node-api` forwards login/register/profile calls to `AUTH_SERVICE_URL` (currently `GO_BACKEND_URL=http://auth-service:8081`).
- The quiz frontend proxies `/api/auth/*` to `auth-service`; all other `/api/*` traffic stays on the quiz backend.
- The gateway routes `/auth/*` to `auth-service`.

Phase 1 keeps the auth and quiz tables in the same `genshinquiz` database: the quiz container still applies goose migrations, and `auth-service` starts only after the quiz health check passes. Splitting the auth schema/database is a separate later step.

### Initial admin

The first administrator is selected by **email**, not `user_id`:

- `BOOTSTRAP_ADMIN_EMAIL` plus `BOOTSTRAP_ADMIN_PASSWORD` on first start
- only applies while there are zero `user_role=1` users
- if the email already exists and is verified, it is promoted; its password is not changed
- if it exists but is unverified, the password must match, or set `BOOTSTRAP_ADMIN_RESET_PASSWORD=true` to take it over
- if it does not exist, the account is created with the configured password

For later promotion, run `go run ./cmd/seed-admin -email you@example.com` inside `auth-service`. `GATEWAY_ADMIN_EMAILS` and `MIAO_OWNER_EMAILS` are the stable email whitelists; the old `*_USER_IDS` settings are compatibility only.

### Sessions and single sign-on

- **Session cookie.** Login, registration and OAuth create a row in `user_sessions` and set an opaque `HttpOnly` cookie (`moelink_session`; only its SHA-256 is stored). Apps keep the 15-minute access token in memory only and renew it with `POST /auth/session/refresh`. `POST /auth/logout` revokes the session; `POST /auth/logout-all` revokes every session of the user.
- **Same registrable domain** (`*.moelink.site`): set `SESSION_COOKIE_DOMAIN=.moelink.site`; every subdomain shares the session, so login/logout in one app shows up in the others on their next refresh (page load or focus). Locally, cookies on `localhost` ignore the port, so `:5173` and `:3000` share the session.
- **Other domains** use OAuth 2.0 authorization code + PKCE: register the app in `SSO_CLIENTS`, send the user to `https://moelink.site/sso/authorize` (`client_id`, `redirect_uri`, `state`, `code_challenge`, `code_challenge_method=S256`), then redeem the code at `POST /auth/sso/token`. These tokens carry `client_id` and are rejected by all MoeLink services; the partner's own backend verifies them with the JWKS.
- **Signing key.** `auth-service` creates an ES256 key at `JWT_KEY_FILE` on first start (volume `auth_keys`; back it up, losing it signs everyone out). `JWT_SECRET` remains only for OAuth state / link tokens inside `auth-service`.
- **Trusted origins.** Cookie-based endpoints and CORS credentials are limited to `OAUTH_ALLOWED_REDIRECT_ORIGINS`.

## Configuration and deployment

The root `.env.example` documents the variables used by Compose. Copy it to `.env` and replace placeholder secrets before starting a deployment. On first run, `setup.sh` can create the copy automatically, but it does not overwrite an existing `.env`.

See [README.md](./README.md) for deployment steps and [DEVELOPMENT.md](./DEVELOPMENT.md) for local Compose workflows.
