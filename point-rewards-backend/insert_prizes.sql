-- 奖品数据插入脚本
-- 执行前请确保已经运行了数据库迁移创建了相关表

-- 清空现有奖品数据（可选）
-- DELETE FROM prize;

-- 插入奖品数据
INSERT INTO prize (id, name, description, image, points, category, stock) VALUES
(1, '50元红包', '现金红包，可直接提现', '/src/assets/red-envelope.png', 500, 'cash', 20),
(2, '100元红包', '现金红包，可直接提现', '/src/assets/red-envelope.png', 1000, 'cash', 15),
(3, '200元红包', '现金红包，可直接提现', '/src/assets/red-envelope.png', 2000, 'cash', 10),
(4, '500元红包', '现金红包，可直接提现', '/src/assets/red-envelope.png', 5000, 'cash', 5),
(5, '20元购物券', '线上购物券，限期使用', '/src/assets/red-envelope.png', 200, 'voucher', 50),
(6, '50元购物券', '线上购物券，限期使用', '/src/assets/red-envelope.png', 500, 'voucher', 30);

-- 查看插入的数据
SELECT * FROM prize ORDER BY id;