-- 初始化 PostgreSQL 数据库
-- 这个文件会在 PostgreSQL 容器首次启动时自动执行

-- 创建数据库（如果不存在）
CREATE DATABASE genshinquiz;
-- AlphaSoul 麻将数据（maj-server / maj 工具用）
CREATE DATABASE majstatus;

-- 创建用户（如果需要额外的用户）
-- CREATE USER genshin_user WITH PASSWORD 'your_password';
-- GRANT ALL PRIVILEGES ON DATABASE genshinquiz TO genshin_user;

-- 设置数据库编码和时区
-- ALTER DATABASE genshinquiz SET timezone TO 'UTC';

-- 注意：实际的表结构和数据由 Goose 迁移文件管理
-- 这个 init.sql 主要用于：
-- 1. 创建数据库
-- 2. 设置基本配置
-- 3. 创建用户和权限（如果需要）