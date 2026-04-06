-- 数据库扩展脚本（与 高德定位与志愿者匹配 设计文档 配套）
-- 执行前请确认数据库为 help，且已存在现有表（users, help_requests 等）
-- 使用方式：mysql -u root -p help < schema-extend.sql  或在客户端中逐段执行

USE help;

-- -------------------------------
-- 用户位置（最近一次上报）
-- -------------------------------
CREATE TABLE IF NOT EXISTS user_locations (
  id           VARCHAR(64) PRIMARY KEY,
  user_id      VARCHAR(64) NOT NULL,
  latitude     DECIMAL(10, 7) NOT NULL,
  longitude    DECIMAL(10, 7) NOT NULL,
  address      VARCHAR(512),
  source       VARCHAR(32),
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user (user_id)
);
CREATE INDEX idx_user_locations_user_id ON user_locations(user_id);

-- -------------------------------
-- 志愿者可服务时间（可选）
-- -------------------------------
CREATE TABLE IF NOT EXISTS volunteer_availability (
  id           VARCHAR(64) PRIMARY KEY,
  user_id      VARCHAR(64) NOT NULL,
  day_of_week  TINYINT NOT NULL COMMENT '1-7',
  start_time   TIME NOT NULL,
  end_time     TIME NOT NULL,
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME ON UPDATE CURRENT_TIMESTAMP
);
CREATE INDEX idx_vol_avail_user ON volunteer_availability(user_id);

-- -------------------------------
-- 志愿者服务范围
-- -------------------------------
CREATE TABLE IF NOT EXISTS service_areas (
  id             VARCHAR(64) PRIMARY KEY,
  user_id        VARCHAR(64) NOT NULL,
  type           VARCHAR(16) NOT NULL COMMENT 'radius|district',
  center_lat     DECIMAL(10, 7),
  center_lng     DECIMAL(10, 7),
  radius_km      DECIMAL(6, 2),
  district_code  VARCHAR(32),
  district_name  VARCHAR(128),
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_service_areas_user ON service_areas(user_id);

-- -------------------------------
-- 站内通知
-- -------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id           VARCHAR(64) PRIMARY KEY,
  user_id      VARCHAR(64) NOT NULL,
  title        VARCHAR(128) NOT NULL,
  body         TEXT,
  type         VARCHAR(32),
  ref_id       VARCHAR(64),
  ref_type     VARCHAR(32),
  is_read      TINYINT(1) DEFAULT 0,
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- -------------------------------
-- 操作审计日志
-- -------------------------------
CREATE TABLE IF NOT EXISTS audit_log (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id       VARCHAR(64),
  action        VARCHAR(64) NOT NULL,
  resource_type VARCHAR(32),
  resource_id   VARCHAR(64),
  detail        TEXT,
  ip            VARCHAR(64),
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_created ON audit_log(created_at);

-- -------------------------------
-- 系统配置
-- -------------------------------
CREATE TABLE IF NOT EXISTS system_config (
  id           VARCHAR(64) PRIMARY KEY,
  config_key   VARCHAR(128) NOT NULL,
  config_value TEXT,
  description  VARCHAR(256),
  updated_at   DATETIME ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_key (config_key)
);

-- -------------------------------
-- 求助查看统计（可选）
-- -------------------------------
CREATE TABLE IF NOT EXISTS request_views (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  request_id   VARCHAR(64) NOT NULL,
  user_id      VARCHAR(64),
  view_type    VARCHAR(16) COMMENT 'list|detail',
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_request_views_request ON request_views(request_id);
