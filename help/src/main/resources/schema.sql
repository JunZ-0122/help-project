-- 创建数据库
CREATE DATABASE IF NOT EXISTS help DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE help;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(32) PRIMARY KEY COMMENT '用户ID',
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    phone VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号',
    password VARCHAR(64) NOT NULL COMMENT '密码（MD5加密）',
    avatar VARCHAR(255) COMMENT '头像URL',
    role VARCHAR(20) NOT NULL COMMENT '角色：help-seeker, volunteer, community',
    status VARCHAR(20) DEFAULT 'offline' COMMENT '状态：online, offline, busy',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    -- 扩展字段
    age INT COMMENT '年龄',
    gender VARCHAR(10) COMMENT '性别：male, female, other',
    address VARCHAR(255) COMMENT '地址',
    emergency_contact VARCHAR(50) COMMENT '紧急联系人',
    emergency_phone VARCHAR(20) COMMENT '紧急联系电话',
    disabilities TEXT COMMENT '残疾情况（JSON数组）',
    certifications TEXT COMMENT '志愿者资质（JSON数组）',
    volunteer_hours INT DEFAULT 0 COMMENT '志愿服务时长',
    rating DECIMAL(3,2) COMMENT '评分',
    
    INDEX idx_phone (phone),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 求助请求表
CREATE TABLE IF NOT EXISTS help_requests (
    id VARCHAR(32) PRIMARY KEY COMMENT '请求ID',
    user_id VARCHAR(32) NOT NULL COMMENT '用户ID',
    user_name VARCHAR(50) NOT NULL COMMENT '用户姓名',
    user_phone VARCHAR(20) NOT NULL COMMENT '用户电话',
    type VARCHAR(20) NOT NULL COMMENT '类型：medical, shopping, repair, companion, emergency, other',
    title VARCHAR(100) NOT NULL COMMENT '标题',
    description TEXT NOT NULL COMMENT '描述',
    location VARCHAR(255) NOT NULL COMMENT '位置',
    latitude DECIMAL(10,7) COMMENT '纬度',
    longitude DECIMAL(10,7) COMMENT '经度',
    urgency VARCHAR(20) NOT NULL COMMENT '紧急程度：low, medium, high, emergency',
    status VARCHAR(20) DEFAULT 'pending' COMMENT '状态：pending, assigned, in-progress, completed, cancelled',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    scheduled_time DATETIME COMMENT '预约时间',
    estimated_duration INT COMMENT '预计时长（分钟）',
    images TEXT COMMENT '图片URL（JSON数组）',
    volunteer_id VARCHAR(32) COMMENT '志愿者ID',
    volunteer_name VARCHAR(50) COMMENT '志愿者姓名',
    completed_at DATETIME COMMENT '完成时间',
    rating INT COMMENT '评分',
    feedback TEXT COMMENT '反馈',
    
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_type (type),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='求助请求表';

-- 志愿者订单表
CREATE TABLE IF NOT EXISTS volunteer_orders (
    id VARCHAR(32) PRIMARY KEY COMMENT '订单ID',
    request_id VARCHAR(32) NOT NULL COMMENT '请求ID',
    volunteer_id VARCHAR(32) NOT NULL COMMENT '志愿者ID',
    volunteer_name VARCHAR(50) NOT NULL COMMENT '志愿者姓名',
    help_seeker_id VARCHAR(32) NOT NULL COMMENT '求助者ID',
    help_seeker_name VARCHAR(50) NOT NULL COMMENT '求助者姓名',
    help_seeker_phone VARCHAR(20) NOT NULL COMMENT '求助者电话',
    type VARCHAR(20) NOT NULL COMMENT '类型',
    title VARCHAR(100) NOT NULL COMMENT '标题',
    description TEXT NOT NULL COMMENT '描述',
    location VARCHAR(255) NOT NULL COMMENT '位置',
    latitude DECIMAL(10,7) COMMENT '纬度',
    longitude DECIMAL(10,7) COMMENT '经度',
    status VARCHAR(20) DEFAULT 'accepted' COMMENT '状态：accepted, in-progress, completed, cancelled',
    accepted_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '接受时间',
    started_at DATETIME COMMENT '开始时间',
    completed_at DATETIME COMMENT '完成时间',
    estimated_duration INT COMMENT '预计时长',
    actual_duration INT COMMENT '实际时长',
    distance DECIMAL(10,2) COMMENT '距离（公里）',
    rating INT COMMENT '评分',
    feedback TEXT COMMENT '反馈',
    images TEXT COMMENT '图片URL（JSON数组）',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    INDEX idx_volunteer_id (volunteer_id),
    INDEX idx_request_id (request_id),
    INDEX idx_status (status),
    FOREIGN KEY (request_id) REFERENCES help_requests(id),
    FOREIGN KEY (volunteer_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='志愿者订单表';

-- 聊天消息表
CREATE TABLE IF NOT EXISTS chat_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '消息ID',
    request_id VARCHAR(32) NOT NULL COMMENT '请求ID',
    sender_id VARCHAR(32) NOT NULL COMMENT '发送者ID',
    sender_name VARCHAR(50) NOT NULL COMMENT '发送者姓名',
    sender_avatar VARCHAR(255) COMMENT '发送者头像',
    receiver_id VARCHAR(32) NOT NULL COMMENT '接收者ID',
    text TEXT NOT NULL COMMENT '消息内容',
    type VARCHAR(20) DEFAULT 'text' COMMENT '类型：text, voice, image, location',
    voice_url VARCHAR(255) COMMENT '语音URL',
    voice_duration INT COMMENT '语音时长（秒）',
    image_url VARCHAR(255) COMMENT '图片URL',
    latitude DECIMAL(10,7) COMMENT '位置纬度',
    longitude DECIMAL(10,7) COMMENT '位置经度',
    is_read BOOLEAN DEFAULT FALSE COMMENT '是否已读',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    INDEX idx_request_id (request_id),
    INDEX idx_sender_id (sender_id),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (request_id) REFERENCES help_requests(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='聊天消息表';

-- 评价表
CREATE TABLE IF NOT EXISTS reviews (
    id VARCHAR(32) PRIMARY KEY COMMENT '评价ID',
    order_id VARCHAR(32) NOT NULL COMMENT '订单ID',
    reviewer_id VARCHAR(32) NOT NULL COMMENT '评价者ID',
    reviewer_name VARCHAR(50) NOT NULL COMMENT '评价者姓名',
    reviewee_id VARCHAR(32) NOT NULL COMMENT '被评价者ID',
    reviewee_name VARCHAR(50) NOT NULL COMMENT '被评价者姓名',
    rating INT NOT NULL COMMENT '评分（1-5）',
    tags TEXT COMMENT '标签（JSON数组）',
    content TEXT COMMENT '评价内容',
    images TEXT COMMENT '图片URL（JSON数组）',
    is_anonymous BOOLEAN DEFAULT FALSE COMMENT '是否匿名',
    reply_content TEXT COMMENT '回复内容',
    reply_time DATETIME COMMENT '回复时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    UNIQUE KEY uk_order_reviewer (order_id, reviewer_id),
    INDEX idx_order_id (order_id),
    INDEX idx_reviewee_id (reviewee_id),
    FOREIGN KEY (order_id) REFERENCES volunteer_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评价表';

-- 志愿者技能标签（社区快速派单匹配）
CREATE TABLE IF NOT EXISTS volunteer_skills (
    user_id VARCHAR(32) NOT NULL COMMENT '志愿者用户 ID',
    skill_code VARCHAR(32) NOT NULL COMMENT 'medical,companion,shopping,repair,emergency,other',
    PRIMARY KEY (user_id, skill_code),
    CONSTRAINT fk_volunteer_skills_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_volunteer_skills_code (skill_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='志愿者技能标签';
