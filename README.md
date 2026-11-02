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
   - Keep `JWT_SECRET` identical across the MoeLink Node API and GenshinQuiz Go API.
   - Set `GATEWAY_ADMIN_USER_IDS` to the MoeLink user IDs permitted to sign in to the gateway dashboard.
   - On Synology or another host where port 5432 is occupied, set `POSTGRES_HOST_PORT=5433` (or another free port). This changes only the host mapping; containers continue to use `postgres:5432`.
4. Start the project:

   ```bash
   docker compose up -d --build
   ```

On Synology Container Manager, create a Project from this directory and its `docker-compose.yml`. Include the complete `repos/` and `config/` directories and the edited `.env`.

Alternatively, `./setup.sh --up` updates repositories and starts Compose after the repositories are clean. On Synology, where Docker requires elevated permissions, use `./setup.sh --up --sudo`. If the script creates `.env` during that run, it stops so that you can edit the secrets before retrying.

### Services and ports

| Service | Host port | Notes |
|---|---:|---|
| GenshinQuiz frontend | 3000 | Static site |
| GenshinQuiz API | 8080 | Go |
| MoeLink frontend | 5173 | Static site |
| MoeLink gateway/dashboard | 8000 | Dashboard: `/_gateway/ui` |
| MoeLink Node API | 8020 | |
| maj-server | 8181 | |
| PostgreSQL | 5432 by default | Bound to loopback; configure with `POSTGRES_HOST_PORT` |

The database is not exposed to the LAN by default. Container-to-container connections use port 5432 regardless of the host port mapping.

## Local frontend development

Use the local Compose override to run both Vite frontends with source mounts and hot reload. Backend, database, and gateway settings remain based on the default Compose file:

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d --build
```

Use the default Compose file alone for static frontend builds. `vue-home` is not currently defined as a Compose service.

## Useful commands

```bash
docker compose ps
docker compose logs -f moe-link node-api
docker compose down
```

`docker compose down -v` also deletes named volumes, including PostgreSQL data; use it only when you intend to erase persistent data.

See [DEVELOPMENT.md](./DEVELOPMENT.md) for development workflows and [ARCHITECTURE.md](./ARCHITECTURE.md) for the system overview.
