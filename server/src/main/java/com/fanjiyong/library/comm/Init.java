package com.fanjiyong.library.comm;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

/**
 * 启动初始化：把 sqls 表的语句全部装进全局 Map。
 * 好处：改 SQL 不用改 Java 代码、不用重新编译，改库后重启即可。
 */
@Component
public class Init implements CommandLineRunner {

    /** 全局 SQL 表：key = sqls.id，value = sqls.sqlb */
    public static Map<String, String> sqlmap = new LinkedHashMap<>();

    private final Sql sql;

    public Init(Sql sql) {
        this.sql = sql;
    }

    @Override
    public void run(String... args) {
        sqlmap = sql.loadAll();
        System.out.println("=================================================");
        System.out.println("图书管理系统启动成功（范记永 2024003296）");
        System.out.println("已加载 SQL 语句：" + sqlmap.size() + " 条");
        System.out.println("访问地址：http://localhost:8080/login.html");
        System.out.println("=================================================");
    }
}
