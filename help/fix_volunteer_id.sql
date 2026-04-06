-- 修复聊天功能：更新 help_requests 表中的 volunteer_id 字段
-- 问题：志愿者无法发送消息，因为 help_requests.volunteer_id 为 NULL

-- 1. 检查当前问题数据
SELECT 
    hr.id,
    hr.user_id,
    hr.volunteer_id,
    hr.volunteer_name,
    hr.status,
    vo.volunteer_id as order_volunteer_id,
    vo.volunteer_name as order_volunteer_name
FROM help_requests hr
LEFT JOIN volunteer_orders vo ON hr.id = vo.request_id
WHERE hr.id = '73a499642b2c45848d599f1288a8d89c';

-- 2. 从 volunteer_orders 表中获取正确的 volunteer_id 并更新
UPDATE help_requests hr
INNER JOIN volunteer_orders vo ON hr.id = vo.request_id
SET 
    hr.volunteer_id = vo.volunteer_id,
    hr.volunteer_name = vo.volunteer_name
WHERE hr.id = '73a499642b2c45848d599f1288a8d89c';

-- 3. 验证修复结果
SELECT 
    id,
    user_id,
    user_name,
    volunteer_id,
    volunteer_name,
    status
FROM help_requests
WHERE id = '73a499642b2c45848d599f1288a8d89c';

-- 4. 修复所有类似的问题（可选）
-- 将所有有订单但 volunteer_id 为空的请求都修复
UPDATE help_requests hr
INNER JOIN volunteer_orders vo ON hr.id = vo.request_id
SET 
    hr.volunteer_id = vo.volunteer_id,
    hr.volunteer_name = vo.volunteer_name
WHERE hr.volunteer_id IS NULL;

-- 5. 最终验证
SELECT COUNT(*) as fixed_count
FROM help_requests hr
INNER JOIN volunteer_orders vo ON hr.id = vo.request_id
WHERE hr.volunteer_id IS NOT NULL;
