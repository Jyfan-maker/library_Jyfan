package com.fanjiyong.library.comm;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.List;
import java.util.Map;

import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

/**
 * SQL 访问类：所有增删改查统一从这里走。
 * 1. 业务代码只写 SQL 的 key，不写 SQL 文本；
 * 2. SQL 文本存在数据库 sqls 表，启动时加载进 Init.sqlmap；
 * 3. 查询类 SQL 由 MySQL 的 JSON_OBJECT / JSON_ARRAYAGG 直接拼 JSON；
 * 4. 全部参数化，禁止拼接用户输入。
 * 修改 sqls 表的 SQL 后需重启服务才生效。
 */
@Repository
public class Sql {

    private final JdbcTemplate jdbc;

    public Sql(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** 按 key 取 SQL 文本，取不到直接报错 */
    public static String text(String key) {
        String s = Init.sqlmap.get(key);
        if (s == null || s.trim().isEmpty()) {
            throw new IllegalStateException("sqls 表中缺少 SQL 定义：" + key);
        }
        return s.trim();
    }

    /** 启动时加载 sqls 表全部语句（全项目唯一硬编码的 SQL） */
    public Map<String, String> loadAll() {
        return jdbc.query("SELECT id, sqlb FROM sqls ORDER BY id", rs -> {
            Map<String, String> map = new java.util.LinkedHashMap<>();
            while (rs.next()) {
                map.put(rs.getString("id").trim(), rs.getString("sqlb"));
            }
            return map;
        });
    }

    /** 增删改：返回受影响行数 */
    public int update(String key, Object... args) {
        return jdbc.update(text(key), args);
    }

    /** 插入：返回自增主键，失败返回 -1 */
    public int insert(String key, Object... args) {
        KeyHolder holder = new GeneratedKeyHolder();
        jdbc.update(con -> {
            PreparedStatement ps = con.prepareStatement(text(key), Statement.RETURN_GENERATED_KEYS);
            for (int i = 0; i < args.length; i++) {
                ps.setObject(i + 1, args[i]);
            }
            return ps;
        }, holder);
        Number generated = holder.getKey();
        return generated == null ? -1 : generated.intValue();
    }

    /** 查单条：返回数据库拼好的 JSON 字符串，无数据返回 null */
    public String one(String key, Object... args) {
        try {
            return jdbc.queryForObject(text(key), String.class, args);
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    /** 查列表：返回 JSON 数组字符串，无数据返回 [] */
    public String list(String key, Object... args) {
        String json = one(key, args);
        return json == null ? "[]" : json;
    }

    /** 查多行多列：返回 List<Map>（演示不用 JSON 聚合的写法） */
    public List<Map<String, Object>> rows(String key, Object... args) {
        return jdbc.queryForList(text(key), args);
    }
}
