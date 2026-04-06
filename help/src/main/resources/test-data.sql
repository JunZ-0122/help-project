-- 测试数据脚本
USE help;

-- 清空现有数据
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE reviews;
TRUNCATE TABLE chat_messages;
TRUNCATE TABLE volunteer_orders;
TRUNCATE TABLE help_requests;
TRUNCATE TABLE volunteer_skills;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;

-- 插入测试用户
-- 密码都是 123456 的 MD5: e10adc3949ba59abbe56e057f20f883e
INSERT INTO users (id, name, phone, password, role, status, age, gender, address, created_at) VALUES
-- 求助者
('user001', '张三', '13800138001', 'e10adc3949ba59abbe56e057f20f883e', 'help-seeker', 'online', 65, 'male', '北京市朝阳区建国路1号', NOW()),
('user002', '李四', '13800138002', 'e10adc3949ba59abbe56e057f20f883e', 'help-seeker', 'offline', 70, 'female', '北京市海淀区中关村大街2号', NOW()),
('user003', '王五', '13800138003', 'e10adc3949ba59abbe56e057f20f883e', 'help-seeker', 'online', 68, 'male', '北京市东城区王府井大街3号', NOW()),

-- 志愿者
('user004', '赵六', '13800138004', 'e10adc3949ba59abbe56e057f20f883e', 'volunteer', 'online', 25, 'male', '北京市西城区西单大街4号', NOW()),
('user005', '孙七', '13800138005', 'e10adc3949ba59abbe56e057f20f883e', 'volunteer', 'online', 28, 'female', '北京市丰台区南三环5号', NOW()),
('user006', '周八', '13800138006', 'e10adc3949ba59abbe56e057f20f883e', 'volunteer', 'busy', 30, 'male', '北京市石景山区石景山路6号', NOW()),

-- 社区管理员
('user007', '吴九', '13800138007', 'e10adc3949ba59abbe56e057f20f883e', 'community', 'online', 35, 'female', '北京市朝阳区社区服务中心', NOW());

-- 更新志愿者信息
UPDATE users SET 
    certifications = '["急救证书", "心理咨询师"]',
    volunteer_hours = 120,
    rating = 4.8
WHERE id = 'user004';

UPDATE users SET 
    certifications = '["护理证书", "营养师"]',
    volunteer_hours = 200,
    rating = 4.9
WHERE id = 'user005';

UPDATE users SET 
    certifications = '["驾驶证", "维修技师"]',
    volunteer_hours = 80,
    rating = 4.5
WHERE id = 'user006';

-- 志愿者技能（快速派单匹配；需已执行 migration-volunteer-skills.sql 建表）
INSERT IGNORE INTO volunteer_skills (user_id, skill_code) VALUES
('user004', 'medical'), ('user004', 'companion'),
('user005', 'medical'), ('user005', 'shopping'), ('user005', 'repair'),
('user006', 'repair'), ('user006', 'shopping'), ('user006', 'emergency');

-- 更新求助者信息
UPDATE users SET 
    disabilities = '["行动不便"]',
    emergency_contact = '张小明',
    emergency_phone = '13900139001'
WHERE id = 'user001';

UPDATE users SET 
    disabilities = '["视力障碍"]',
    emergency_contact = '李小红',
    emergency_phone = '13900139002'
WHERE id = 'user002';

-- 插入求助请求
INSERT INTO help_requests (
    id, user_id, user_name, user_phone, type, title, description, 
    location, latitude, longitude, urgency, status, 
    scheduled_time, estimated_duration, created_at
) VALUES
-- 待分配的请求
('req001', 'user001', '张三', '13800138001', 'medical', '需要陪同就医', 
 '明天上午需要去医院做检查，希望有志愿者陪同', 
 '北京市朝阳区人民医院', 39.9042, 116.4074, 'high', 'pending',
 DATE_ADD(NOW(), INTERVAL 1 DAY), 120, NOW()),

('req002', 'user002', '李四', '13800138002', 'shopping', '帮忙购买生活用品',
 '需要购买一些日常生活用品，自己行动不便',
 '北京市海淀区超市', 39.9833, 116.3167, 'medium', 'pending',
 DATE_ADD(NOW(), INTERVAL 2 DAY), 60, NOW()),

-- 已分配的请求
('req003', 'user003', '王五', '13800138003', 'companion', '需要陪伴聊天',
 '感觉孤独，希望有人陪伴聊天',
 '北京市东城区王府井社区', 39.9139, 116.4074, 'low', 'assigned',
 DATE_ADD(NOW(), INTERVAL 3 DAY), 90, DATE_SUB(NOW(), INTERVAL 1 DAY)),

-- 进行中的请求
('req004', 'user001', '张三', '13800138001', 'repair', '家电维修',
 '家里的洗衣机坏了，需要维修',
 '北京市朝阳区建国路1号', 39.9042, 116.4074, 'medium', 'in-progress',
 NOW(), 60, DATE_SUB(NOW(), INTERVAL 2 DAY)),

-- 已完成的请求
('req005', 'user002', '李四', '13800138002', 'medical', '陪同买药',
 '需要去药店买药',
 '北京市海淀区药店', 39.9833, 116.3167, 'high', 'completed',
 DATE_SUB(NOW(), INTERVAL 3 DAY), 30, DATE_SUB(NOW(), INTERVAL 5 DAY));

-- 更新已分配和进行中的请求的志愿者信息
UPDATE help_requests SET volunteer_id = 'user004', volunteer_name = '赵六' WHERE id = 'req003';
UPDATE help_requests SET volunteer_id = 'user006', volunteer_name = '周八' WHERE id = 'req004';
UPDATE help_requests SET volunteer_id = 'user005', volunteer_name = '孙七', 
       completed_at = DATE_SUB(NOW(), INTERVAL 1 DAY), rating = 5, 
       feedback = '服务非常好，非常感谢！' 
WHERE id = 'req005';

-- 插入志愿者订单
INSERT INTO volunteer_orders (
    id, request_id, volunteer_id, volunteer_name, 
    help_seeker_id, help_seeker_name, help_seeker_phone,
    type, title, description, location, latitude, longitude,
    status, accepted_at, estimated_duration
) VALUES
-- 已接受的订单
('order001', 'req003', 'user004', '赵六',
 'user003', '王五', '13800138003',
 'companion', '需要陪伴聊天', '感觉孤独，希望有人陪伴聊天',
 '北京市东城区王府井社区', 39.9139, 116.4074,
 'accepted', DATE_SUB(NOW(), INTERVAL 1 DAY), 90),

-- 进行中的订单
('order002', 'req004', 'user006', '周八',
 'user001', '张三', '13800138001',
 'repair', '家电维修', '家里的洗衣机坏了，需要维修',
 '北京市朝阳区建国路1号', 39.9042, 116.4074,
 'in-progress', DATE_SUB(NOW(), INTERVAL 2 DAY), 60),

-- 已完成的订单
('order003', 'req005', 'user005', '孙七',
 'user002', '李四', '13800138002',
 'medical', '陪同买药', '需要去药店买药',
 '北京市海淀区药店', 39.9833, 116.3167,
 'completed', DATE_SUB(NOW(), INTERVAL 5 DAY), 30);

-- 更新进行中的订单
UPDATE volunteer_orders SET started_at = DATE_SUB(NOW(), INTERVAL 1 HOUR) WHERE id = 'order002';

-- 更新已完成的订单
UPDATE volunteer_orders SET 
    started_at = DATE_SUB(NOW(), INTERVAL 4 DAY),
    completed_at = DATE_SUB(NOW(), INTERVAL 1 DAY),
    actual_duration = 35,
    distance = 2.5,
    rating = 5,
    feedback = '服务态度好，很专业'
WHERE id = 'order003';

-- 插入聊天消息
INSERT INTO chat_messages (
    request_id, sender_id, sender_name, receiver_id, 
    text, type, is_read, created_at
) VALUES
-- req003 的聊天记录
('req003', 'user003', '王五', 'user004', '你好，什么时候方便？', 'text', TRUE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
('req003', 'user004', '赵六', 'user003', '明天下午2点可以吗？', 'text', TRUE, DATE_SUB(NOW(), INTERVAL 23 HOUR)),
('req003', 'user003', '王五', 'user004', '可以的，谢谢！', 'text', TRUE, DATE_SUB(NOW(), INTERVAL 22 HOUR)),

-- req004 的聊天记录
('req004', 'user001', '张三', 'user006', '师傅，大概什么时候能到？', 'text', TRUE, DATE_SUB(NOW(), INTERVAL 2 HOUR)),
('req004', 'user006', '周八', 'user001', '我马上就到，大约10分钟', 'text', TRUE, DATE_SUB(NOW(), INTERVAL 1 HOUR)),
('req004', 'user001', '张三', 'user006', '好的，我在家等您', 'text', FALSE, DATE_SUB(NOW(), INTERVAL 1 HOUR)),

-- req005 的聊天记录
('req005', 'user002', '李四', 'user005', '需要买什么药呢？', 'text', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY)),
('req005', 'user002', '李四', 'user005', '降压药和感冒药', 'text', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY)),
('req005', 'user005', '孙七', 'user002', '好的，我已经买好了，马上送过去', 'text', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY));

-- 插入评价
INSERT INTO reviews (
    id, order_id, reviewer_id, reviewer_name, 
    reviewee_id, reviewee_name, rating, tags, content,
    is_anonymous, created_at
) VALUES
('review001', 'order003', 'user002', '李四',
 'user005', '孙七', 5, '["服务好", "态度好", "专业"]',
 '志愿者服务非常好，态度很好，很专业，非常感谢！',
 FALSE, DATE_SUB(NOW(), INTERVAL 1 DAY));

-- 查询统计信息
SELECT '=== 用户统计 ===' AS info;
SELECT role, COUNT(*) as count FROM users GROUP BY role;

SELECT '=== 求助请求统计 ===' AS info;
SELECT status, COUNT(*) as count FROM help_requests GROUP BY status;

SELECT '=== 志愿者订单统计 ===' AS info;
SELECT status, COUNT(*) as count FROM volunteer_orders GROUP BY status;

SELECT '=== 聊天消息统计 ===' AS info;
SELECT request_id, COUNT(*) as message_count FROM chat_messages GROUP BY request_id;

SELECT '=== 评价统计 ===' AS info;
SELECT COUNT(*) as total_reviews, AVG(rating) as avg_rating FROM reviews;

SELECT '测试数据插入完成！' AS result;
