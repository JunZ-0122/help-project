-- 演示：插入 1 条「待接单 + 有经纬度」的紧急求助，供志愿者端「附近求助」红框样式验收。
-- 前置：已执行 schema.sql，且存在求助者用户（与 test-data.sql 一致时可用 user001）。
-- 用法：mysql -u root -p help < seed-demo-emergency-request.sql

USE help;

-- 若与旧数据主键冲突，可先删除：DELETE FROM help_requests WHERE id = 'req_demo_emergency_ui';

INSERT INTO help_requests (
  id, user_id, user_name, user_phone,
  type, title, description,
  location, latitude, longitude,
  urgency, status,
  created_at
) VALUES (
  'req_demo_emergency_ui',
  'user001',
  '张三',
  '13800138001',
  'emergency',
  '紧急求助',
  '【演示数据】需尽快协助，用于志愿者首页紧急任务红框展示。',
  '北京市朝阳区建国路1号附近',
  39.9042000,
  116.4074000,
  'emergency',
  'pending',
  NOW()
);

SELECT id, type, urgency, status, title FROM help_requests WHERE id = 'req_demo_emergency_ui';
