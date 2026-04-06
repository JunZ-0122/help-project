-- 社区「数据统计」演示：在已执行 test-data.sql 后运行，将完成时间与评价时间拉到近期，便于本月/本周/环比有活数据。
-- mysql -u root -p help < seed-community-statistics.sql

USE help;

SET @now = NOW();

-- 已完成订单：完成时间落在本月且最近 7 天内（便于本周趋势与本月帮扶次数）
UPDATE volunteer_orders
SET completed_at = DATE_SUB(@now, INTERVAL 1 DAY)
WHERE id = 'order003' AND status = 'completed';

-- 评价时间落在本月（满意度统计）
UPDATE reviews
SET created_at = DATE_SUB(@now, INTERVAL 1 DAY)
WHERE id = 'review001';

-- 求助创建时间拉到近期，「高频求助类型」本月有分布（需已执行 test-data.sql）
UPDATE help_requests
SET created_at = DATE_SUB(@now, INTERVAL 2 DAY)
WHERE id IN ('req001', 'req002', 'req003', 'req004', 'req005');

SELECT 'seed-community-statistics applied' AS status;
