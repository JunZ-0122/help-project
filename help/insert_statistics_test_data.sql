-- 插入统计测试数据
USE help;

-- 更新现有求助请求的完成时间（模拟本周数据）
UPDATE help_requests 
SET completed_at = DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 7) DAY),
    status = 'completed'
WHERE id IN (
    SELECT * FROM (
        SELECT id FROM help_requests 
        WHERE status = 'pending' 
        LIMIT 20
    ) AS temp
);

-- 更新志愿者评分
UPDATE users 
SET rating = 4.5 + (RAND() * 0.5),
    volunteer_hours = FLOOR(20 + RAND() * 30)
WHERE role = 'volunteer';

-- 为志愿者添加更多完成的订单
INSERT INTO volunteer_orders (
    id, request_id, volunteer_id, volunteer_name, 
    help_seeker_id, help_seeker_name, help_seeker_phone,
    type, title, description, location,
    status, accepted_at, started_at, completed_at,
    estimated_duration, actual_duration, rating
)
SELECT 
    CONCAT('order_', UUID_SHORT()),
    r.id,
    v.id,
    v.name,
    r.user_id,
    r.user_name,
    r.user_phone,
    r.type,
    r.title,
    r.description,
    r.location,
    'completed',
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 30) DAY),
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 30) DAY),
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 7) DAY),
    r.estimated_duration,
    FLOOR(30 + RAND() * 60),
    FLOOR(4 + RAND() * 1)
FROM help_requests r
CROSS JOIN (
    SELECT id, name FROM users WHERE role = 'volunteer' LIMIT 3
) v
WHERE r.status = 'completed'
LIMIT 15;

-- 插入更多不同类型的求助请求
INSERT INTO help_requests (
    id, user_id, user_name, user_phone, type, title, description, 
    location, urgency, status, created_at, completed_at
) VALUES
-- 就医协助
('req_medical_1', 'user_seeker_1', '张大爷', '13800138001', 'medical', '需要陪同去医院', '需要志愿者陪同去医院做检查', '北京市朝阳区', 'high', 'completed', DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),
('req_medical_2', 'user_seeker_1', '张大爷', '13800138001', 'medical', '取药帮助', '需要帮忙去医院取药', '北京市朝阳区', 'medium', 'completed', DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),
('req_medical_3', 'user_seeker_1', '张大爷', '13800138001', 'medical', '体检陪同', '需要陪同体检', '北京市朝阳区', 'low', 'completed', DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),

-- 出行协助
('req_shopping_1', 'user_seeker_1', '张大爷', '13800138001', 'shopping', '超市购物', '需要帮忙去超市买菜', '北京市朝阳区', 'low', 'completed', DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY)),
('req_shopping_2', 'user_seeker_1', '张大爷', '13800138001', 'shopping', '买日用品', '需要购买日用品', '北京市朝阳区', 'low', 'completed', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),

-- 生活帮扶
('req_companion_1', 'user_seeker_1', '张大爷', '13800138001', 'companion', '聊天陪伴', '希望有人陪我聊聊天', '北京市朝阳区', 'low', 'completed', DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
('req_companion_2', 'user_seeker_1', '张大爷', '13800138001', 'companion', '散步陪伴', '希望有人陪我散步', '北京市朝阳区', 'low', 'completed', DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),

-- 陪伴服务
('req_repair_1', 'user_seeker_1', '张大爷', '13800138001', 'repair', '修理电器', '家里的电器坏了需要修理', '北京市朝阳区', 'medium', 'completed', DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),

-- 其他
('req_other_1', 'user_seeker_1', '张大爷', '13800138001', 'other', '其他帮助', '需要其他方面的帮助', '北京市朝阳区', 'low', 'completed', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY));

COMMIT;

SELECT '统计测试数据插入完成' AS message;
