# 图书管理系统 · 数据库课程设计

> 作者：范记永　学号：2024003296　数据库：`library_Jyfan`
> 技术栈：Spring Boot 2.7 + JDK 21 + MySQL + 原生 JavaScript 前端

一个满足课程设计任务书要求的完整图书管理系统。数据库含 **5 张表、3 组真实外键、124 本不重复图书**；后端实现了登录鉴权、图书 CRUD 与模糊搜索、分类管理、借还书事务、多维度统计；前端为免构建的原生 JS 单页应用。

---

## 一、目录结构

```
library_Jyfan_project/
├── db/                      数据库脚本
│   ├── library_Jyfan.sql    ★ 完整建库脚本（可直接导入）
│   └── gen_sql.py           脚本生成器（改图书数据后重跑）
├── server/                  Spring Boot 后端
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/fanjiyong/library/
│       │   ├── LibraryApplication.java   启动类
│       │   ├── comm/   工具类（Sql/Sql访问/DbConfig/Init/Md5/R）
│       │   └── web/    控制器（登录/图书/分类/借阅）
│       └── resources/
│           ├── application.properties
│           ├── dbconfig.json            数据库账号密码
│           └── static/                  前端页面（login.html/index.html/js/css）
└── doc/
    ├── 课程设计报告.md       ★ 完整报告（2000+ 字，含 E-R 图、表结构、接口清单）
    └── 演示说明.md           ★ 一页纸答辩/演示指南
```

## 二、环境要求

| 软件 | 版本 | 说明 |
| :--- | :--- | :--- |
| JDK | 21 | 需设置 `JAVA_HOME` |
| Maven | 3.9+ | 已配置阿里云镜像加速 |
| MySQL | 5.7 / 8.0 / 26.7 | 需支持 JSON 函数；脚本已兼容无 MD5() 的新版本 |

## 三、快速启动（三步）

**1. 导入数据库**
```bash
mysql --default-character-set=utf8mb4 -u root -p < db/library_Jyfan.sql
```
脚本开头有 `DROP DATABASE IF EXISTS`，可重复执行（会清空重建，注意备份）。

**2. 修改数据库配置**（如本机 MySQL 密码不同）
编辑 `server/src/main/resources/dbconfig.json` 中的用户名与密码。

**3. 编译并启动服务**
```bash
cd server
mvn -DskipTests package
java -jar target/library.jar
```
浏览器打开 <http://localhost:8080/login.html>。

> ⚠️ 两个注意点：① `sqls` 表的 SQL 在**服务启动时一次性加载进内存**，改动后必须重启服务才生效；② 密码为 MD5 密文存储，真实系统应改用加盐哈希（bcrypt），报告中有说明。

## 四、测试账号

| 用户名 | 密码 | 角色 |
| :--- | :--- | :--- |
| admin | 123456 | 管理员 |
| fanjiyong | 123456 | 普通读者 |

## 五、功能模块与接口

| 模块 | 主要接口（POST） | 说明 |
| :--- | :--- | :--- |
| 登录 | `/api/login` | MD5 校验，返回 Session；未登录访问业务接口返回 401 |
| 图书 | `/api/book/list` `/api/book/save` `/api/book/delete` `/api/book/stat` | 增删改查、标题/作者模糊搜索、总数/库存/码洋统计 |
| 分类 | `/api/category/list` `/api/category/save` `/api/category/delete` | 分类维护，被图书引用时禁止删除 |
| 借阅 | `/api/borrow/borrow` `/api/borrow/return` `/api/borrow/mine` `/api/borrow/stat` | 借书扣库存、还书加库存（**事务保证原子性**）、按读者查记录、按分类统计 |

统一返回格式：`{ "code": 0, "msg": "...", "data": ... }`。

## 六、数据库设计要点（答辩高频问题）

- **为什么分类独立成表？** 参考实现把分类存成图书表里的字符串，存在数据冗余、违反 3NF。本设计拆出 `category` 表，图书只存 `category_id` 外键。
- **三组外键**：`book.category_id → category.id`；`borrow.user_id → users.id`；`borrow.book_id → book.id`。`borrow` 是"读者↔图书"多对多关系的分解中间表。
- **金额用 `DECIMAL(10,2)`** 而非 float，避免精度误差。
- **索引**：`users.username` 唯一索引、`book.title/author` 供 LIKE 搜索、`borrow.user_id` 供按读者查询。
- **完整性保护**：重复借书拦截、库存不足拦截、删除被引用图书被外键阻止。

## 七、交接/答辩建议

1. 先看 `doc/演示说明.md`，按里面的流程现场操作一遍（**答辩是现场随机指定操作并解释背后 SQL，只放录屏判不合格**）。
2. 再看 `doc/课程设计报告.md` 理解设计意图，重点是 E-R 图、关系模式、范式说明、事务设计。
3. 改动 SQL 后记得重启服务；改数据库密码后 `dbconfig.json` 要同步。

---

**仓库**：<https://github.com/Jyfan-maker/library_Jyfan>（Private）
