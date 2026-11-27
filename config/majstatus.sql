-- AlphaSoul 麻将统计表（majstatus 库）
-- 应用里的 SQL 不给标识符加引号，PostgreSQL 会折叠成小写，所以这里统一用小写列名。
-- API 层通过 AS 别名还原前端需要的 sumRank1 / RICHI 等键名。
-- 本文件可重复执行：表已存在时跳过，种子行用 ON CONFLICT 去重。

\connect majstatus

CREATE TABLE IF NOT EXISTS maj_selfbattle (
  id integer PRIMARY KEY,
  plays integer NOT NULL DEFAULT 0,
  subplays integer NOT NULL DEFAULT 0,
  summinus integer NOT NULL DEFAULT 0,
  sumrank1 integer NOT NULL DEFAULT 0,
  sumrank2 integer NOT NULL DEFAULT 0,
  sumrank3 integer NOT NULL DEFAULT 0,
  sumrank4 integer NOT NULL DEFAULT 0,
  sumfulu integer NOT NULL DEFAULT 0,
  sumlizhi integer NOT NULL DEFAULT 0,
  sumchong integer NOT NULL DEFAULT 0,
  sumhu integer NOT NULL DEFAULT 0,
  sumzimo integer NOT NULL DEFAULT 0,
  sumpt integer NOT NULL DEFAULT 0,
  sumxun integer NOT NULL DEFAULT 0,
  maxzhuang integer NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS yaku_list (
  id integer PRIMARY KEY,
  richi integer NOT NULL DEFAULT 0,
  tsumo integer NOT NULL DEFAULT 0,
  chankan integer NOT NULL DEFAULT 0,
  rinshan integer NOT NULL DEFAULT 0,
  haitei integer NOT NULL DEFAULT 0,
  houtei integer NOT NULL DEFAULT 0,
  haku integer NOT NULL DEFAULT 0,
  hatsu integer NOT NULL DEFAULT 0,
  chun integer NOT NULL DEFAULT 0,
  menfeng integer NOT NULL DEFAULT 0,
  changfeng integer NOT NULL DEFAULT 0,
  tanyao integer NOT NULL DEFAULT 0,
  ipeikou integer NOT NULL DEFAULT 0,
  pinhu integer NOT NULL DEFAULT 0,
  chanta integer NOT NULL DEFAULT 0,
  ittsuu integer NOT NULL DEFAULT 0,
  sanshoku_doujun integer NOT NULL DEFAULT 0,
  wrichi integer NOT NULL DEFAULT 0,
  sanshoku_douko integer NOT NULL DEFAULT 0,
  san_kantsu integer NOT NULL DEFAULT 0,
  toitoi integer NOT NULL DEFAULT 0,
  san_anko integer NOT NULL DEFAULT 0,
  shou_sangen integer NOT NULL DEFAULT 0,
  honrou integer NOT NULL DEFAULT 0,
  chiitoi integer NOT NULL DEFAULT 0,
  junchan integer NOT NULL DEFAULT 0,
  honiisou integer NOT NULL DEFAULT 0,
  ryanpeikou integer NOT NULL DEFAULT 0,
  chiniisou integer NOT NULL DEFAULT 0,
  ippatsu integer NOT NULL DEFAULT 0,
  bao integer NOT NULL DEFAULT 0,
  libao integer NOT NULL DEFAULT 0,
  hongbao integer NOT NULL DEFAULT 0,
  nagashi_mankan integer NOT NULL DEFAULT 0,
  tenhou integer NOT NULL DEFAULT 0,
  chiihou integer NOT NULL DEFAULT 0,
  kokushi integer NOT NULL DEFAULT 0,
  kokushi_13 integer NOT NULL DEFAULT 0,
  sianko integer NOT NULL DEFAULT 0,
  sianko_tanki integer NOT NULL DEFAULT 0,
  dai_sangen integer NOT NULL DEFAULT 0,
  shou_suushii integer NOT NULL DEFAULT 0,
  dai_susshii integer NOT NULL DEFAULT 0,
  tsuuiisou integer NOT NULL DEFAULT 0,
  chinroutou integer NOT NULL DEFAULT 0,
  ryuuiisou integer NOT NULL DEFAULT 0,
  chuuren_poutou integer NOT NULL DEFAULT 0,
  junsei_chuuren_poutou integer NOT NULL DEFAULT 0,
  suu_kantsu integer NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS max_win (
  id integer PRIMARY KEY,
  hand text NOT NULL DEFAULT '',
  fulou text NOT NULL DEFAULT '',
  type integer NOT NULL DEFAULT 0,
  pt integer NOT NULL DEFAULT 0,
  fan integer NOT NULL DEFAULT 0,
  fu integer NOT NULL DEFAULT 0
);

INSERT INTO maj_selfbattle (id) VALUES (1), (2), (3), (4) ON CONFLICT (id) DO NOTHING;
INSERT INTO yaku_list (id) VALUES (1), (2), (3), (4) ON CONFLICT (id) DO NOTHING;
INSERT INTO max_win (id) VALUES (1), (2), (3), (4) ON CONFLICT (id) DO NOTHING;
