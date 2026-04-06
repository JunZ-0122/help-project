-- Restore canonical manual integration data for chat and order flow checks.
USE help;

-- Remove temporary smoke-test messages if they exist.
DELETE FROM chat_messages WHERE text LIKE 'smoke-%';

-- Restore canonical roles and statuses for test users.
UPDATE users SET role = 'help-seeker', status = 'online' WHERE id = 'user001';
UPDATE users SET role = 'help-seeker', status = 'offline' WHERE id = 'user002';
UPDATE users SET role = 'help-seeker', status = 'online' WHERE id = 'user003';
UPDATE users SET role = 'volunteer', status = 'online' WHERE id = 'user004';
UPDATE users SET role = 'volunteer', status = 'online' WHERE id = 'user005';
UPDATE users SET role = 'volunteer', status = 'busy' WHERE id = 'user006';
UPDATE users SET role = 'community', status = 'online' WHERE id = 'user007';

-- Restore help request linkage used by manual chat verification.
UPDATE help_requests
SET user_id = 'user003',
    user_name = (SELECT name FROM users WHERE id = 'user003'),
    user_phone = (SELECT phone FROM users WHERE id = 'user003'),
    volunteer_id = 'user004',
    volunteer_name = (SELECT name FROM users WHERE id = 'user004'),
    status = 'assigned',
    completed_at = NULL,
    rating = NULL,
    feedback = NULL
WHERE id = 'req003';

UPDATE help_requests
SET user_id = 'user001',
    user_name = (SELECT name FROM users WHERE id = 'user001'),
    user_phone = (SELECT phone FROM users WHERE id = 'user001'),
    volunteer_id = 'user006',
    volunteer_name = (SELECT name FROM users WHERE id = 'user006'),
    status = 'in-progress'
WHERE id = 'req004';

UPDATE help_requests
SET user_id = 'user002',
    user_name = (SELECT name FROM users WHERE id = 'user002'),
    user_phone = (SELECT phone FROM users WHERE id = 'user002'),
    volunteer_id = 'user005',
    volunteer_name = (SELECT name FROM users WHERE id = 'user005'),
    status = 'completed'
WHERE id = 'req005';

-- Restore volunteer orders so both accepted and in-progress paths are available.
UPDATE volunteer_orders
SET request_id = 'req003',
    volunteer_id = 'user004',
    volunteer_name = (SELECT name FROM users WHERE id = 'user004'),
    help_seeker_id = 'user003',
    help_seeker_name = (SELECT name FROM users WHERE id = 'user003'),
    help_seeker_phone = (SELECT phone FROM users WHERE id = 'user003'),
    status = 'accepted',
    started_at = NULL,
    completed_at = NULL,
    actual_duration = NULL,
    distance = NULL,
    rating = NULL,
    feedback = NULL
WHERE id = 'order001';

UPDATE volunteer_orders
SET request_id = 'req004',
    volunteer_id = 'user006',
    volunteer_name = (SELECT name FROM users WHERE id = 'user006'),
    help_seeker_id = 'user001',
    help_seeker_name = (SELECT name FROM users WHERE id = 'user001'),
    help_seeker_phone = (SELECT phone FROM users WHERE id = 'user001'),
    status = 'in-progress',
    started_at = DATE_SUB(NOW(), INTERVAL 1 HOUR)
WHERE id = 'order002';

UPDATE volunteer_orders
SET request_id = 'req005',
    volunteer_id = 'user005',
    volunteer_name = (SELECT name FROM users WHERE id = 'user005'),
    help_seeker_id = 'user002',
    help_seeker_name = (SELECT name FROM users WHERE id = 'user002'),
    help_seeker_phone = (SELECT phone FROM users WHERE id = 'user002'),
    status = 'completed'
WHERE id = 'order003';
