-- 快速修复 volunteer_orders 表缺失字段
-- 执行方式：mysql -u root -p help < quick-fix-volunteer-orders.sql

USE help;

-- 添加 created_at 和 updated_at 字段
ALTER TABLE volunteer_orders 
ADD COLUMN IF NOT EXISTS created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
ADD COLUMN IF NOT EXISTS updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间';

-- 验证字段已添加
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT, 
    EXTRA
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_SCHEMA = 'help' 
    AND TABLE_NAME = 'volunteer_orders'
    AND COLUMN_NAME IN ('created_at', 'updated_at');

-- 显示完整表结构
DESC volunteer_orders;

SELECT '修复完成！' AS status;
