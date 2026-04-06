-- 检查数据库表结构脚本
-- 用于验证表名和字段是否正确

USE help;

-- 1. 检查所有表是否存在
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    CREATE_TIME
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'help'
ORDER BY TABLE_NAME;

-- 2. 检查 users 表结构
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'help' AND TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;

-- 3. 检查 help_requests 表结构
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'help' AND TABLE_NAME = 'help_requests'
ORDER BY ORDINAL_POSITION;

-- 4. 检查 volunteer_orders 表结构（重点检查）
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'help' AND TABLE_NAME = 'volunteer_orders'
ORDER BY ORDINAL_POSITION;

-- 5. 检查 chat_messages 表结构（重点检查）
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'help' AND TABLE_NAME = 'chat_messages'
ORDER BY ORDINAL_POSITION;

-- 6. 检查 reviews 表结构（重点检查）
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'help' AND TABLE_NAME = 'reviews'
ORDER BY ORDINAL_POSITION;

-- 7. 检查是否有旧的表名（单数形式）
SELECT TABLE_NAME 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'help' 
AND TABLE_NAME IN ('volunteer_order', 'chat_message', 'review');

-- 如果上面的查询返回结果，说明存在旧表名，需要重命名
