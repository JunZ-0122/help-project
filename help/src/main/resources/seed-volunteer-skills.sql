-- 在 migration-volunteer-skills.sql 执行后运行；与 test-data 中志愿者 ID 对应
USE help;

INSERT IGNORE INTO volunteer_skills (user_id, skill_code) VALUES
('user004', 'medical'), ('user004', 'companion'),
('user005', 'medical'), ('user005', 'shopping'), ('user005', 'repair'),
('user006', 'repair'), ('user006', 'shopping'), ('user006', 'emergency');
