package com.fanjiyong.library.comm;

import java.io.InputStream;
import java.util.Map;

import javax.sql.DataSource;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zaxxer.hikari.HikariDataSource;

/**
 * 数据库连接配置：从 classpath 下的 dbconfig.json 读取。
 * 换库/换账号只改配置文件，不改代码；打包后配置文件在 jar 根目录。
 */
@Configuration
public class DbConfig {

    private static final String CONFIG_FILE = "dbconfig.json";

    @Bean
    public DataSource dataSource() throws Exception {
        ClassPathResource resource = new ClassPathResource(CONFIG_FILE);
        if (!resource.exists()) {
            throw new IllegalStateException("找不到数据库配置文件 " + CONFIG_FILE);
        }

        Map<String, Object> cfg;
        try (InputStream in = resource.getInputStream()) {
            cfg = new ObjectMapper().readValue(in, Map.class);
        }

        String host = str(cfg, "host", "127.0.0.1");
        int port = (int) num(cfg, "port", 3306);
        String database = str(cfg, "database", "library_Jyfan");
        String user = str(cfg, "user", "root");
        String password = str(cfg, "password", "");

        if (database.isEmpty()) {
            throw new IllegalStateException("dbconfig.json 中的 database 不能为空");
        }

        String url = "jdbc:mysql://" + host + ":" + port + "/" + database
                + "?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=utf8&allowPublicKeyRetrieval=true";

        HikariDataSource ds = new HikariDataSource();
        ds.setDriverClassName("com.mysql.cj.jdbc.Driver");
        ds.setJdbcUrl(url);
        ds.setUsername(user);
        ds.setPassword(password);
        ds.setMaximumPoolSize(10);
        ds.setConnectionTimeout(5000);

        System.out.println("数据库配置：" + host + ":" + port + "/" + database + "，账号 " + user);
        return ds;
    }

    private static String str(Map<String, Object> cfg, String key, String def) {
        Object v = cfg.get(key);
        if (v == null) {
            return def;
        }
        String s = String.valueOf(v).trim();
        return s.isEmpty() ? def : s;
    }

    private static double num(Map<String, Object> cfg, String key, double def) {
        Object v = cfg.get(key);
        if (v == null) {
            return def;
        }
        try {
            return Double.parseDouble(String.valueOf(v).trim());
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
