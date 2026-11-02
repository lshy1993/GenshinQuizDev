# System Architecture / 系统架构

This repository is the deployment workspace for several independently versioned applications. The root Compose project connects their containers on one private Docker network.

本仓库是多个独立版本管理应用的部署工作区。根目录的 Compose 项目将各容器连接到同一个内部 Docker 网络。

## Services

| Compose service | Application | Responsibility |
|---|---|---|
| `genshinquiz-frontend` | React + Vite, served by Nginx | GenshinQuiz user interface |
| `genshinquiz-backend` | Go + Chi | GenshinQuiz API and authoritative GenshinQuiz user data |
| `moe-link` | Vue + Vite, served by Nginx | MoeLink user interface |
| `node-api` | Node.js + Express + PostgreSQL | MoeLink API, forum, shop, wallet, and unified-user integration |
| `maj-server` | Node.js | Mahjong service |
| `moelink-gateway` | Node.js | API reverse proxy, health monitoring, statistics, dashboard, and release status |
| `postgres` | PostgreSQL | Persistent storage for the applications |

The default Compose file builds both web frontends as static assets served by Nginx. `docker-compose.local.yml` is a standalone, complete Compose file for local development (it does not extend the default file); it runs the same services but serves these two frontends from Vite development servers with source mounts and hot reload.

## Network and access

Containers connect to each other using Compose service names, for example:

- `node-api:8020`
- `genshinquiz-backend:8080`
- `postgres:5432`

The public host ports are declared in `docker-compose.yml`. PostgreSQL is bound to the host loopback address only, with a default host port of 5432. Set `POSTGRES_HOST_PORT` in the root `.env` to use another host port; the internal container port remains 5432.

The gateway listens on port 8000. It exposes `/node-api` and `/go-api` proxy prefixes, monitors configured services, and serves its dashboard at `/_gateway/ui`.

## Databases and migrations

PostgreSQL initializes the `moelink` database through `POSTGRES_DB`. The root `config/init.sql` additionally creates `genshinquiz` and `majstatus` when PostgreSQL initializes a new data directory.

- The Go backend applies its Goose migrations during container startup.
- The Node API applies Knex migrations to the `moelink` database before starting.
- The Node API also connects to `genshinquiz` for unified-user reads and to `majstatus` for Mahjong data.
- `config/init.sql` is run only when the PostgreSQL data directory is first initialized. Existing volumes are not changed by edits to that file.

Persistent database files are stored in the `postgres_data` named volume. Removing the Compose project does not remove named volumes unless `-v` is specified.

## Unified authentication

The Go backend and Node API use the same HS256 `JWT_SECRET` for unified authentication. Set it in the root `.env` before deployment and keep it identical for both services. The Node API reads the GenshinQuiz user database; the Go backend remains the authority for those accounts.

## Configuration and deployment

The root `.env.example` documents the variables used by Compose. Copy it to `.env` and replace placeholder secrets before starting a deployment. On first run, `setup.sh` can create the copy automatically, but it does not overwrite an existing `.env`.

See [README.md](./README.md) for deployment steps and [DEVELOPMENT.md](./DEVELOPMENT.md) for local Compose workflows.
