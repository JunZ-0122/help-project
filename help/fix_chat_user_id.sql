-- 修复聊天功能：确保 help_requests 表中的 user_id 字段不为空
-- 问题：志愿者无法发送消息，因为 targetUserId 为空

-- 1. 检查当前数据状态
SELECT 
    id,
    user_id,
    user_name,
    volunteer_id,
    volunteer_name,
    title,
    status,
    created_at
FROM help_requests
WHERE status IN ('assigned', 'in-progress', 'pending')
ORDER BY created_at DESC
LIMIT 10;

-- 2. 查找 user_id 为 NULL 的记录
SELECT 
    id,
    title,
    status,
    user_name,
    volunteer_id
FROM help_requests
WHERE user_id IS NULL;

-- 3. 修复：将 user_id 设置为 'user001'（默认求助者）
-- 注意：这是临时修复，实际应该根据业务逻辑设置正确的 user_id
UPDATE help_requests 
SET user_id = 'user001'
WHERE user_id IS NULL;

-- 4. 验证修复结果
SELECT 
    id,
    user_id,
    user_name,
    volunteer_id,
    volunteer_name,
    title,
    status
FROM help_requests
WHERE status IN ('assigned', 'in-progress')
ORDER BY created_at DESC
LIMIT 5;

-- 5. 检查是否还有空值
SELECT COUNT(*) as null_user_id_count
FROM help_requests
WHERE user_id IS NULL;
