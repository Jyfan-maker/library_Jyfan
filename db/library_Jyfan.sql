-- ============================================================
-- 图书管理系统 数据库建库脚本
-- 作者：范记永  学号：2024003296
-- 数据库：library_Jyfan（独立新建，不碰任何已有库）
-- 执行方式：mysql -u root -p < library_Jyfan.sql
-- 特性：5 张表 / 3 组真实外键 / 字段注释 / 索引 / 124 本图书 / SQL 集中管理
-- ============================================================

DROP DATABASE IF EXISTS library_Jyfan;
CREATE DATABASE library_Jyfan DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE library_Jyfan;

-- ------------------------------------------------------------
-- 1. 用户表（读者/管理员）：password 存 MD5(明文) 的 32 位十六进制
-- ------------------------------------------------------------
CREATE TABLE users (
  id         INT AUTO_INCREMENT PRIMARY KEY COMMENT '用户编号',
  username   VARCHAR(50)  NOT NULL UNIQUE COMMENT '登录名（唯一）',
  password   VARCHAR(32)  NOT NULL COMMENT 'MD5 密文，32 位',
  real_name  VARCHAR(50)  DEFAULT '' COMMENT '真实姓名',
  role       VARCHAR(20)  DEFAULT 'user' COMMENT '角色：admin 管理员 / user 普通读者',
  phone      VARCHAR(20)  DEFAULT '' COMMENT '联系电话',
  created_at DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户表（读者与管理员）';

-- ------------------------------------------------------------
-- 2. 分类表：把分类独立成表，消除图书表中的字符串冗余（满足 3NF）
-- ------------------------------------------------------------
CREATE TABLE category (
  id         INT AUTO_INCREMENT PRIMARY KEY COMMENT '分类编号',
  name       VARCHAR(50)  NOT NULL UNIQUE COMMENT '分类名称（唯一）',
  remark     VARCHAR(200) DEFAULT '' COMMENT '分类说明',
  created_at DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '图书分类表';

-- ------------------------------------------------------------
-- 3. 图书表：category_id 外键关联分类表；金额用 DECIMAL 不用浮点
-- ------------------------------------------------------------
CREATE TABLE book (
  id          INT AUTO_INCREMENT PRIMARY KEY COMMENT '图书编号',
  title       VARCHAR(100)  NOT NULL COMMENT '书名',
  author      VARCHAR(50)   DEFAULT '' COMMENT '作者',
  isbn        VARCHAR(32)   DEFAULT '' COMMENT 'ISBN 书号',
  category_id INT           NOT NULL COMMENT '所属分类编号（外键）',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '单价，精确到分',
  stock       INT           NOT NULL DEFAULT 0 COMMENT '库存数量',
  created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '上架时间',
  CONSTRAINT fk_book_category FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_book_price CHECK (price >= 0),
  CONSTRAINT chk_book_stock CHECK (stock >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '图书表';

-- ------------------------------------------------------------
-- 4. 借阅表：拆解"读者-图书"多对多的中间表，含两个真实外键
-- ------------------------------------------------------------
CREATE TABLE borrow (
  id         INT AUTO_INCREMENT PRIMARY KEY COMMENT '借阅编号',
  user_id    INT          NOT NULL COMMENT '读者编号（外键）',
  book_id    INT          NOT NULL COMMENT '图书编号（外键）',
  borrow_at  DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '借出时间',
  return_at  DATETIME     DEFAULT NULL COMMENT '归还时间，未还为空',
  status     VARCHAR(10)  NOT NULL DEFAULT '在借' COMMENT '状态：在借 / 已还',
  fine       DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '逾期罚金',
  remark     VARCHAR(200) DEFAULT '' COMMENT '备注',
  CONSTRAINT fk_borrow_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_borrow_book FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_borrow_status CHECK (status IN ('在借','已还')),
  CONSTRAINT chk_borrow_fine CHECK (fine >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '借阅记录表';

-- ------------------------------------------------------------
-- 5. SQL 语句表：全项目 SQL 集中存放，服务启动时加载进全局 Map
-- ------------------------------------------------------------
CREATE TABLE sqls (
  id     VARCHAR(64) PRIMARY KEY COMMENT 'SQL 的 key',
  sqlb   TEXT NOT NULL COMMENT 'SQL 语句原文',
  remark VARCHAR(200) DEFAULT '' COMMENT '说明'
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'SQL 集中管理表';

-- ------------------------------------------------------------
-- 6. 索引：为高频查询列建立索引
-- ------------------------------------------------------------
CREATE INDEX idx_book_title    ON book(title);       -- 书名模糊搜索
CREATE INDEX idx_book_author   ON book(author);      -- 作者模糊搜索
CREATE INDEX idx_book_category ON book(category_id); -- 按分类统计/筛选
CREATE INDEX idx_borrow_user   ON borrow(user_id);   -- 查某读者借阅记录
CREATE INDEX idx_borrow_book   ON borrow(book_id);   -- 查某书借阅记录
CREATE INDEX idx_borrow_status ON borrow(status);    -- 筛选在借记录

-- ------------------------------------------------------------
-- 7. 初始数据：分类
-- ------------------------------------------------------------
INSERT INTO category (name, remark) VALUES
  ('计算机与互联网', '计算机与互联网类图书'),
  ('文学小说', '文学小说类图书'),
  ('历史', '历史类图书'),
  ('经济管理', '经济管理类图书'),
  ('哲学心理', '哲学心理类图书'),
  ('自然科学', '自然科学类图书'),
  ('教育', '教育类图书'),
  ('艺术设计', '艺术设计类图书'),
  ('工程技术', '工程技术类图书'),
  ('法律', '法律类图书'),
  ('医学健康', '医学健康类图书'),
  ('外语', '外语类图书');

-- ------------------------------------------------------------
-- 8. 初始数据：用户（明文密码统一 123456，库中仅存 MD5 密文）
--    123456 的 MD5 = e10adc3949ba59abbe56e057f20f883e
-- ------------------------------------------------------------
-- 123456 的 MD5 密文固定为 e10adc3949ba59abbe56e057f20f883e
-- 直接写密文常量而不调用 MD5() 函数，兼容 MySQL 5.7/8.0/26.x 各版本
INSERT INTO users (username, password, real_name, role, phone) VALUES
  ('admin',      'e10adc3949ba59abbe56e057f20f883e', '系统管理员', 'admin', '13800000000'),
  ('fanjiyong',  'e10adc3949ba59abbe56e057f20f883e', '范记永', 'user', '13900000001'),
  ('zhangsan',   'e10adc3949ba59abbe56e057f20f883e', '张三', 'user', '13900000002'),
  ('lisi',       'e10adc3949ba59abbe56e057f20f883e', '李四', 'user', '13900000003');

-- ------------------------------------------------------------
-- 9. 初始数据：图书（共 124 本，书名互不重复，分属 12 个分类）
-- ------------------------------------------------------------
INSERT INTO book (title, author, isbn, category_id, price, stock) VALUES
  ('数据库系统概论（第6版）', '王珊', '9787040564102', 1, 59.80, 30),
  ('MySQL必知必会', '福达', '9787115375592', 1, 39.00, 25),
  ('算法导论（第3版）', '托马斯·科尔曼', '9787111407010', 1, 128.00, 12),
  ('深入理解计算机系统', '兰德尔·布莱恩特', '9787111544937', 1, 138.00, 15),
  ('计算机网络（第7版）', '谢希仁', '9787115428025', 1, 49.00, 28),
  ('操作系统概念', '亚伯拉罕·西尔伯沙茨', '9787111357629', 1, 78.00, 20),
  ('数据结构与算法分析', '克利福德·沙弗', '9787115369539', 1, 68.00, 22),
  ('Java核心技术 卷I', '凯·霍斯特曼', '9787115388615', 1, 108.00, 18),
  ('Head First设计模式', '埃里克·弗里曼', '9787508348443', 1, 68.00, 16),
  ('Python编程：从入门到实践', '埃里克·马瑟斯', '9787115420510', 1, 89.00, 26),
  ('编译原理', '阿尔弗雷德·阿霍', '9787111213826', 1, 78.00, 14),
  ('计算机程序的构造和解释', '哈罗德·阿贝尔森', '9787111261810', 1, 88.00, 13),
  ('活着', '余华', '9787506365437', 2, 28.00, 40),
  ('围城', '钱钟书', '9787020084383', 2, 32.00, 35),
  ('骆驼祥子', '老舍', '9787020085311', 2, 26.00, 30),
  ('边城', '沈从文', '9787020084352', 2, 24.00, 28),
  ('红楼梦', '曹雪芹', '9787020002207', 2, 59.80, 25),
  ('三国演义', '罗贯中', '9787020008729', 2, 55.00, 26),
  ('水浒传', '施耐庵', '9787020008736', 2, 55.00, 26),
  ('西游记', '吴承恩', '9787020008743', 2, 55.00, 28),
  ('百年孤独', '加西亚·马尔克斯', '9787544253993', 2, 39.80, 22),
  ('平凡的世界', '路遥', '9787530212004', 2, 68.00, 20),
  ('三体', '刘慈欣', '9787536692930', 2, 23.00, 45),
  ('呐喊', '鲁迅', '9787020008774', 2, 22.00, 32),
  ('史记', '司马迁', '9787101003070', 3, 68.00, 20),
  ('资治通鉴', '司马光', '9787101055834', 3, 88.00, 15),
  ('全球通史', '斯塔夫里阿诺斯', '9787301084714', 3, 68.00, 18),
  ('明朝那些事儿', '当年明月', '9787510700035', 3, 45.00, 30),
  ('万历十五年', '黄仁宇', '9787101052727', 3, 32.00, 24),
  ('人类简史', '赫拉利', '9787508647357', 3, 68.00, 22),
  ('中国近代史', '蒋廷黻', '9787532766226', 3, 36.00, 20),
  ('罗马帝国衰亡史', '爱德华·吉本', '9787100029414', 3, 98.00, 10),
  ('枪炮、病菌与钢铁', '贾雷德·戴蒙德', '9787532752144', 3, 58.00, 16),
  ('春秋左传注', '杨伯峻', '9787101082860', 3, 128.00, 8),
  ('国富论', '亚当·斯密', '9787100011164', 4, 45.00, 22),
  ('资本论', '马克思', '9787010014805', 4, 68.00, 18),
  ('经济学原理', '曼昆', '9787301132027', 4, 88.00, 20),
  ('管理学', '斯蒂芬·罗宾斯', '9787300088816', 4, 68.00, 24),
  ('营销管理', '菲利普·科特勒', '9787300136888', 4, 98.00, 14),
  ('会计学原理', '葛家澍', '9787300148744', 4, 42.00, 26),
  ('财务管理', '罗斯', '9787111554027', 4, 78.00, 16),
  ('经济学', '萨缪尔森', '9787115122904', 4, 88.00, 17),
  ('竞争战略', '迈克尔·波特', '9787508045156', 4, 45.00, 21),
  ('从0到1', '彼得·蒂尔', '9787508656175', 4, 39.80, 28),
  ('论语', '孔子', '9787101005341', 5, 22.00, 35),
  ('道德经', '老子', '9787101065399', 5, 20.00, 35),
  ('理想国', '柏拉图', '9787100020382', 5, 35.00, 24),
  ('存在与时间', '海德格尔', '9787100123581', 5, 58.00, 12),
  ('西方哲学史', '罗素', '9787100010551', 5, 78.00, 15),
  ('心理学与生活', '津巴多', '9787115533862', 5, 88.00, 18),
  ('思考，快与慢', '丹尼尔·卡尼曼', '9787508633558', 5, 69.00, 20),
  ('梦的解析', '弗洛伊德', '9787100017574', 5, 32.00, 22),
  ('影响力', '罗伯特·西奥迪尼', '9787220096100', 5, 45.00, 25),
  ('自卑与超越', '阿德勒', '9787512510641', 5, 36.00, 23),
  ('时间简史', '史蒂芬·霍金', '9787535239757', 6, 45.00, 26),
  ('物种起源', '达尔文', '9787100025060', 6, 48.00, 20),
  ('昆虫记', '法布尔', '9787502765500', 6, 42.00, 22),
  ('几何原本', '欧几里得', '9787301158220', 6, 38.00, 18),
  ('自然哲学的数学原理', '牛顿', '9787100040521', 6, 68.00, 12),
  ('自私的基因', '理查德·道金斯', '9787508638577', 6, 48.00, 19),
  ('星际穿越', '基普·索恩', '9787535793913', 6, 58.00, 16),
  ('数学之美', '吴军', '9787115329113', 6, 45.00, 27),
  ('地球的故事', '房龙', '9787532754056', 6, 32.00, 24),
  ('从一到无穷大', '伽莫夫', '9787506291337', 6, 35.00, 21),
  ('爱弥儿', '卢梭', '9787100011315', 7, 45.00, 20),
  ('民主主义与教育', '杜威', '9787100110804', 7, 42.00, 18),
  ('给教师的建议', '苏霍姆林斯基', '9787504138833', 7, 38.00, 24),
  ('爱的教育', '亚米契斯', '9787101076081', 7, 28.00, 30),
  ('窗边的小豆豆', '黑柳彻子', '9787544251530', 7, 32.00, 28),
  ('教学勇气', '帕克·帕尔默', '9787567506782', 7, 39.00, 20),
  ('课程与教学的基本原理', '泰勒', '9787504159760', 7, 36.00, 19),
  ('教育心理学', '奥恩斯坦', '9787309073388', 7, 55.00, 16),
  ('终身教育引论', '朗格朗', '9787504149730', 7, 30.00, 22),
  ('学会生存', '联合国教科文组织', '9787504118583', 7, 34.00, 21),
  ('艺术的故事', '贡布里希', '9787543325037', 8, 88.00, 18),
  ('美的历程', '李泽厚', '9787802309633', 8, 45.00, 25),
  ('世界现代设计史', '王受之', '9787500648277', 8, 68.00, 17),
  ('设计中的设计', '原研哉', '9787560742639', 8, 58.00, 20),
  ('中国美术史', '李豫闽', '9787533454962', 8, 52.00, 16),
  ('摄影的艺术', '布鲁斯·巴恩博', '9787115266433', 8, 68.00, 14),
  ('音乐的故事', '房龙', '9787532745245', 8, 32.00, 22),
  ('建筑空间组合论', '彭一刚', '9787112035681', 8, 48.00, 18),
  ('色彩构成', '杨仁敏', '9787562147355', 8, 36.00, 24),
  ('平面设计史', '菲利普·梅格斯', '9787500649991', 8, 78.00, 12),
  ('机械设计基础', '杨可桢', '9787040186289', 9, 42.00, 24),
  ('理论力学', '哈尔滨工业大学', '9787040206093', 9, 45.00, 22),
  ('材料力学', '刘鸿文', '9787040192104', 9, 46.00, 21),
  ('电路', '邱关源', '9787040196713', 9, 48.00, 20),
  ('电子技术基础', '康华光', '9787040177835', 9, 55.00, 18),
  ('工程制图', '大连理工大学', '9787040230570', 9, 38.00, 26),
  ('自动控制原理', '胡寿松', '9787030185261', 9, 52.00, 17),
  ('土木工程材料', '陈志源', '9787564123456', 9, 42.00, 20),
  ('计算机组成原理', '唐朔飞', '9787040223909', 9, 45.00, 23),
  ('软件工程', '张海藩', '9787115172056', 9, 48.00, 22),
  ('刑法学', '张明楷', '9787511882290', 10, 88.00, 15),
  ('民法学', '王利明', '9787511882276', 10, 82.00, 16),
  ('法理学', '张文显', '9787040196119', 10, 45.00, 22),
  ('宪法学', '许崇德', '9787300117570', 10, 38.00, 24),
  ('行政法学', '胡建淼', '9787300077026', 10, 42.00, 20),
  ('合同法', '王利明', '9787300068888', 10, 48.00, 18),
  ('知识产权法', '吴汉东', '9787300160324', 10, 45.00, 19),
  ('国际法', '邵沙平', '9787300096531', 10, 40.00, 21),
  ('商法学', '赵旭东', '9787511882269', 10, 52.00, 16),
  ('法律逻辑学', '雍琦', '9787503678822', 10, 32.00, 25),
  ('黄帝内经', '佚名', '9787117086901', 11, 58.00, 18),
  ('伤寒论', '张仲景', '9787117096351', 11, 42.00, 20),
  ('本草纲目', '李时珍', '9787117094937', 11, 98.00, 10),
  ('外科学', '陈孝平', '9787117173077', 11, 88.00, 14),
  ('内科学', '葛均波', '9787117173039', 11, 88.00, 14),
  ('人体解剖学', '柏树令', '9787117163573', 11, 68.00, 16),
  ('生理学', '朱大年', '9787117163535', 11, 52.00, 18),
  ('药理学', '朱依谆', '9787117152898', 11, 58.00, 17),
  ('诊断学', '陈文彬', '9787117094982', 11, 62.00, 15),
  ('护理学基础', '姜安丽', '9787117160800', 11, 48.00, 19),
  ('牛津英汉双解词典', '牛津大学出版社', '9787100066827', 12, 128.00, 12),
  ('朗文当代高级英语辞典', '朗文', '9787560081007', 12, 118.00, 13),
  ('新概念英语（第一册）', '亚历山大', '9787560015506', 12, 32.00, 30),
  ('英语语法大全', '夸克', '9787560026885', 12, 68.00, 18),
  ('日语能力考试N3', '西藤洋一', '9787560071891', 12, 45.00, 22),
  ('标准日本语（初级）', '人民教育出版社', '9787107201947', 12, 38.00, 26),
  ('法语基础', '马晓宏', '9787560029510', 12, 42.00, 20),
  ('德语教程', '北京大学', '9787301065304', 12, 45.00, 18),
  ('西班牙语速成', '陆经生', '9787560078238', 12, 36.00, 22),
  ('英语词汇的奥秘', '蒋争', '9787506259557', 12, 28.00, 28);

-- ------------------------------------------------------------
-- 10. 初始数据：借阅示例（若干在借 / 已还记录）
-- ------------------------------------------------------------
INSERT INTO borrow (user_id, book_id, borrow_at, return_at, status, fine) VALUES
  (2, 1,  DATE_SUB(NOW(), INTERVAL 5 DAY), NULL, '在借', 0.00),
  (2, 13, DATE_SUB(NOW(), INTERVAL 2 DAY), NULL, '在借', 0.00),
  (3, 3,  DATE_SUB(NOW(), INTERVAL 20 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY), '已还', 0.00),
  (3, 25, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), '已还', 2.00),
  (4, 37, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL, '在借', 0.00);

-- ------------------------------------------------------------
-- 11. SQL 模板（查询类由 MySQL 直接拼 JSON；SQL 文本内单引号写两个）
-- ------------------------------------------------------------
INSERT INTO sqls (id, sqlb, remark) VALUES
('user_login',
 'SELECT JSON_OBJECT(''id'', id, ''username'', username, ''realName'', IFNULL(real_name,''''), ''role'', role) FROM users WHERE username = ? AND password = ?',
 '登录校验：用户名 + MD5 密文'),
('user_profile',
 'SELECT JSON_OBJECT(''id'', id, ''username'', username, ''realName'', IFNULL(real_name,''''), ''role'', role, ''phone'', IFNULL(phone,'''')) FROM users WHERE id = ?',
 '按 id 查用户'),
('user_exists',
 'SELECT COUNT(*) FROM users WHERE username = ?',
 '注册时检查用户名是否已存在'),
('user_register',
 'INSERT INTO users (username, password, real_name) VALUES (?, ?, ?)',
 '注册新用户：密码为 MD5 密文'),
('category_list',
 'SELECT IFNULL(JSON_ARRAYAGG(JSON_OBJECT(''id'', t.id, ''name'', t.name, ''remark'', IFNULL(t.remark,''''))), JSON_ARRAY()) FROM (SELECT * FROM category ORDER BY id) t',
 '分类列表'),
('category_exists',
 'SELECT COUNT(*) FROM category WHERE name = ?',
 '检查分类名是否重复'),
('category_add',
 'INSERT INTO category (name, remark) VALUES (?, ?)',
 '新增分类'),
('category_update',
 'UPDATE category SET name = ?, remark = ? WHERE id = ?',
 '修改分类'),
('category_delete',
 'DELETE FROM category WHERE id = ?',
 '删除分类（若有图书引用则被外键阻止）'),
('book_list',
 'SELECT IFNULL(JSON_ARRAYAGG(JSON_OBJECT(''id'', t.id, ''title'', t.title, ''author'', IFNULL(t.author,''''), ''isbn'', IFNULL(t.isbn,''''), ''categoryId'', t.category_id, ''categoryName'', IFNULL(t.category_name,''''), ''price'', t.price, ''stock'', t.stock, ''createdAt'', DATE_FORMAT(t.created_at, ''%Y-%m-%d %H:%i''))), JSON_ARRAY()) FROM (SELECT b.*, IFNULL(c.name,'''') category_name FROM book b LEFT JOIN category c ON b.category_id = c.id ORDER BY b.id DESC) t',
 '图书列表（联表显示分类名）'),
('book_search',
 'SELECT IFNULL(JSON_ARRAYAGG(JSON_OBJECT(''id'', t.id, ''title'', t.title, ''author'', IFNULL(t.author,''''), ''isbn'', IFNULL(t.isbn,''''), ''categoryId'', t.category_id, ''categoryName'', IFNULL(t.category_name,''''), ''price'', t.price, ''stock'', t.stock, ''createdAt'', DATE_FORMAT(t.created_at, ''%Y-%m-%d %H:%i''))), JSON_ARRAY()) FROM (SELECT b.*, IFNULL(c.name,'''') category_name FROM book b LEFT JOIN category c ON b.category_id = c.id WHERE b.title LIKE ? OR b.author LIKE ? OR b.isbn LIKE ? ORDER BY b.id DESC) t',
 '图书模糊搜索：三个参数均为 %关键字%'),
('book_add',
 'INSERT INTO book (title, author, isbn, category_id, price, stock) VALUES (?, ?, ?, ?, ?, ?)',
 '新增图书'),
('book_update',
 'UPDATE book SET title = ?, author = ?, isbn = ?, category_id = ?, price = ?, stock = ? WHERE id = ?',
 '修改图书'),
('book_delete',
 'DELETE FROM book WHERE id = ?',
 '删除图书（若有在借记录则被外键阻止）'),
('book_stat',
 'SELECT JSON_OBJECT(''total'', COUNT(*), ''stock'', IFNULL(SUM(stock),0), ''value'', IFNULL(SUM(price * stock),0)) FROM book',
 '图书统计：总数 / 库存总量 / 库存总价值'),
('book_stock_dec',
 'UPDATE book SET stock = stock - 1 WHERE id = ? AND stock > 0',
 '借书扣库存：仅当库存大于 0 时生效，返回影响行数判断是否成功'),
('book_stock_inc',
 'UPDATE book SET stock = stock + 1 WHERE id = ?',
 '还书加库存'),
('borrow_list',
 'SELECT IFNULL(JSON_ARRAYAGG(JSON_OBJECT(''id'', t.id, ''userName'', t.username, ''bookTitle'', t.title, ''borrowAt'', DATE_FORMAT(t.borrow_at, ''%Y-%m-%d %H:%i''), ''returnAt'', IFNULL(DATE_FORMAT(t.return_at, ''%Y-%m-%d %H:%i''),''''), ''status'', t.status, ''fine'', t.fine)), JSON_ARRAY()) FROM (SELECT bw.*, u.username, b.title FROM borrow bw JOIN users u ON bw.user_id = u.id JOIN book b ON bw.book_id = b.id ORDER BY bw.id DESC) t',
 '借阅记录列表（联表显示读者与书名）'),
('borrow_by_user',
 'SELECT IFNULL(JSON_ARRAYAGG(JSON_OBJECT(''id'', t.id, ''bookTitle'', t.title, ''borrowAt'', DATE_FORMAT(t.borrow_at, ''%Y-%m-%d %H:%i''), ''returnAt'', IFNULL(DATE_FORMAT(t.return_at, ''%Y-%m-%d %H:%i''),''''), ''status'', t.status, ''fine'', t.fine)), JSON_ARRAY()) FROM (SELECT bw.*, b.title FROM borrow bw JOIN book b ON bw.book_id = b.id WHERE bw.user_id = ? ORDER BY bw.id DESC) t',
 '查询某读者的借阅记录'),
('borrow_add',
 'INSERT INTO borrow (user_id, book_id, status) VALUES (?, ?, ''在借'')',
 '借书：新增借阅记录（与 book_stock_dec 在同一事务中执行）'),
('borrow_return',
 'UPDATE borrow SET status = ''已还'', return_at = NOW() WHERE id = ? AND status = ''在借''',
 '还书：更新状态与归还时间（与 book_stock_inc 在同一事务中执行）'),
('borrow_active',
 'SELECT COUNT(*) FROM borrow WHERE user_id = ? AND book_id = ? AND status = ''在借''',
 '检查某读者是否已借某书且未归还'),
('borrow_book_of',
 'SELECT JSON_OBJECT(''bookId'', book_id) FROM borrow WHERE id = ?',
 '按借阅编号查图书编号（还书加库存用）'),
('borrow_stat',
 'SELECT IFNULL(JSON_ARRAYAGG(JSON_OBJECT(''name'', t.name, ''cnt'', t.cnt)), JSON_ARRAY()) FROM (SELECT IFNULL(c.name,''未分类'') name, COUNT(bw.id) cnt FROM borrow bw JOIN book b ON bw.book_id = b.id LEFT JOIN category c ON b.category_id = c.id GROUP BY c.name ORDER BY cnt DESC) t',
 '按分类统计借阅次数（GROUP BY 聚合）'),
('category_stat',
 'SELECT IFNULL(JSON_ARRAYAGG(JSON_OBJECT(''name'', t.name, ''cnt'', t.cnt)), JSON_ARRAY()) FROM (SELECT IFNULL(c.name,''未分类'') name, COUNT(*) cnt FROM book b LEFT JOIN category c ON b.category_id = c.id GROUP BY c.name ORDER BY cnt DESC) t',
 '按分类统计图书册数（GROUP BY 聚合）');

-- ------------------------------------------------------------
-- 12. 初始化完成提示
-- ------------------------------------------------------------
SELECT CONCAT('library_Jyfan 初始化完成：图书 ', (SELECT COUNT(*) FROM book),
              ' 本，分类 ', (SELECT COUNT(*) FROM category),
              ' 个，SQL 模板 ', (SELECT COUNT(*) FROM sqls), ' 条') AS msg;
