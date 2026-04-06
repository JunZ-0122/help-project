-- 志愿者技能标签（用于快速派单智能匹配），执行前请 USE help;
CREATE TABLE IF NOT EXISTS volunteer_skills (
    user_id VARCHAR(32) NOT NULL COMMENT '志愿者用户 ID',
    skill_code VARCHAR(32) NOT NULL COMMENT '技能编码：medical,companion,shopping,repair,emergency,other',
    PRIMARY KEY (user_id, skill_code),
    CONSTRAINT fk_volunteer_skills_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='志愿者技能标签';

CREATE INDEX idx_volunteer_skills_code ON volunteer_skills (skill_code);
