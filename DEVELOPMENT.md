# Development Guide / 开发指南

This repository is a Compose workspace for several separately versioned applications. Start commands from the repository root unless a section says otherwise.

本仓库通过 Compose 编排多个独立版本管理的应用。除非特别说明，命令都从仓库根目录执行。

## Docker frontend modes

### Static mode (deployment default)

The default `docker-compose.yml` builds the GenshinQuiz and MoeLink frontends and serves their generated files with Nginx:

```bash
docker compose up -d --build
```

### Vite hot reload (local development)

Use the standalone local Compose file:

```bash
docker compose -f docker-compose.local.yml up -d
```

`docker-compose.local.yml` defines every service on its own and differs from the default file only in that the GenshinQuiz and MoeLink frontends (Vite) and the gateway (`bun --watch`) run directly on the `oven/bun` image with mounted source directories. `vue-home` is not currently a Compose service.

To return to static mode, run:

```bash
docker compose -f docker-compose.local.yml down
docker compose up -d --build
```

The override uses the same published frontend ports (3000 and 5173), so do not run both modes simultaneously for the same Compose project.

## Services

| Service | Host port | Description |
|---|---:|---|
| `genshinquiz-frontend` | 3000 | GenshinQuiz frontend |
| `genshinquiz-backend` | 8080 | Go quiz API (`/auth/*` moved out) |
| `auth-service` | 8081 | Go authentication service |
| `moe-link` | 5173 | MoeLink frontend |
| `moelink-gateway` | 8000 | API gateway and dashboard |
| `node-api` | 8020 | MoeLink API |
| `stock-worker` | 8182 (loopback) | Real stock data API and crawl scheduler |
| `maj-server` | 8181 | Mahjong service |
| `postgres` | 5432 by default | PostgreSQL, host binding is loopback-only |

Containers connect to PostgreSQL at `postgres:5432`. To avoid a host-side port conflict, set `POSTGRES_HOST_PORT` in the root `.env` (for example `5433`); this does not change the port used between containers.

## Initial deployment

1. Copy `.env.example` to `.env` if it does not exist. `./setup.sh` does this automatically.
2. Set private values for `JWT_SECRET`, `POSTGRES_PASSWORD`, and `GATEWAY_ADMIN_TOKEN`. `JWT_SECRET` is only used by `auth-service`; the other services verify login tokens with the public key served at `AUTH_JWKS_URL`.
3. If this is a fresh deployment, run `./setup.sh` to fetch the application repositories and initialize their submodules.
4. Start all services:

   ```bash
   docker compose up -d --build
   ```

On Synology Container Manager, create a Project from the root directory and use the root `docker-compose.yml`. The directory must include `repos/`, `config/`, and the configured `.env`.

The Compose file runs database migrations as part of service startup: Goose migrations for the Go API and Knex migrations for the MoeLink database. PostgreSQL's `config/init.sql` runs only when its data directory is first initialized.

## Working on individual applications

### GenshinQuiz frontend

```bash
cd repos/frontend
bun install
bun run dev
```

The Vite development server uses port 3000. Use the root `docker-compose.local.yml` when you want the frontend container to proxy to the other services on the Compose network.

### MoeLink frontend

```bash
cd repos/MoeLink
bun install
bun run dev
```

The Vite development server uses port 5173. For an application build, run `bun run build-only`. `bun run build` also runs the TypeScript check.

### Go API

The Go API source is in `repos/backend`. For the containerized workflow, use the root Compose service. Its container runs Goose migrations and starts the server. For local Go development, consult `repos/backend/README.md` and the Taskfile in that repository.

### MoeLink Node API

The Node API source is in `repos/node-api`. For local development:

```bash
cd repos/node-api
npm install
npx knex migrate:latest
node app.js
```

Configure local database connection variables using that repository's `.env.example`. The root Compose workflow supplies its container-specific database settings.

## Operations

```bash
docker compose ps
docker compose logs -f <service>
docker compose restart <service>
docker compose down
```

`docker compose down -v` removes named volumes, including PostgreSQL data. Do not use it unless you intend to delete persistent data.

`./setup.sh` fetches the root and child repositories over SSH, checks out each remote `main` branch (falling back to `master` when needed), and fast-forward updates only. It skips dirty repositories rather than overwriting local changes. Use `./setup.sh --up` to rebuild/start after updating, or `./setup.sh --up --sudo` if Docker requires `sudo`.

See [README.md](./README.md) for deployment setup and the service/port overview.
