-- 数据库表结构更新脚本
-- 用于已经创建了数据库但字段不匹配的情况

USE help;

-- 1. 更新 volunteer_orders 表，添加缺失的字段
ALTER TABLE volunteer_orders 
ADD COLUMN IF NOT EXISTS created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' AFTER images,
ADD COLUMN IF NOT EXISTS updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER created_at;

-- 2. 检查表名是否正确（如果表名错误，需要重命名）
-- 如果你的表名是 volunteer_order（单数），需要重命名为 volunteer_orders（复数）
-- RENAME TABLE volunteer_order TO volunteer_orders;

-- 如果你的表名是 chat_message（单数），需要重命名为 chat_messages（复数）
-- RENAME TABLE chat_message TO chat_messages;

-- 如果你的表名是 review（单数），需要重命名为 reviews（复数）
-- RENAME TABLE review TO reviews;

-- 3. 验证表结构
SHOW CREATE TABLE users;
SHOW CREATE TABLE help_requests;
SHOW CREATE TABLE volunteer_orders;
SHOW CREATE TABLE chat_messages;
SHOW CREATE TABLE reviews;
