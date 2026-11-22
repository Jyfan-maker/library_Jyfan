package com.fanjiyong.library.web;

import java.util.Map;

import javax.servlet.http.HttpSession;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fanjiyong.library.comm.Md5;
import com.fanjiyong.library.comm.R;
import com.fanjiyong.library.comm.Sql;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 登录相关接口（JSON 请求 / JSON 响应）
 * POST /api/login     登录，成功后 uid/uname/role 写入 HttpSession
 * POST /api/logout    退出
 * GET  /api/me        当前登录用户
 * POST /api/register  注册（MD5 入库）
 */
@RestController
@RequestMapping("/api")
public class LoginController {

    private final Sql sql;
    private final ObjectMapper json;

    public LoginController(Sql sql, ObjectMapper json) {
        this.sql = sql;
        this.json = json;
    }

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody(required = false) Map<String, Object> body, HttpSession session) {
        String username = body == null ? "" : str(body.get("username"));
        String password = body == null ? "" : str(body.get("password"));
        if (username.isEmpty() || password.isEmpty()) {
            return R.fail("用户名和密码不能为空");
        }
        // 库里存的是 MD5，先把输入密码做 MD5 再比对
        String userJson = sql.one("user_login", username, Md5.md5(password));
        if (userJson == null) {
            return R.fail("用户名或密码错误");
        }
        Map<String, Object> user = readMap(userJson);
        session.setAttribute("uid", user.get("id"));
        session.setAttribute("uname", user.get("username"));
        session.setAttribute("role", user.get("role"));
        user.remove("password");
        return R.ok(user);
    }

    @PostMapping("/logout")
    public Map<String, Object> logout(HttpSession session) {
        session.invalidate();
        return R.ok(null);
    }

    @GetMapping("/me")
    public Map<String, Object> me(HttpSession session) {
        Object uid = session.getAttribute("uid");
        if (uid == null) {
            return R.noLogin();
        }
        String userJson = sql.one("user_profile", uid);
        return userJson == null ? R.noLogin() : R.ok(readMap(userJson));
    }

    @PostMapping("/register")
    public Map<String, Object> register(@RequestBody(required = false) Map<String, Object> body) {
        String username = body == null ? "" : str(body.get("username"));
        String password = body == null ? "" : str(body.get("password"));
        String realName = body == null ? "" : str(body.get("realName"));
        if (username.isEmpty() || password.isEmpty()) {
            return R.fail("用户名和密码不能为空");
        }
        String exists = sql.one("user_exists", username);
        if (exists != null && !"0".equals(exists.trim())) {
            return R.fail("用户名已存在");
        }
        int id = sql.insert("user_register", username, Md5.md5(password), realName);
        return id > 0 ? R.ok(id) : R.fail("注册失败");
    }

    private Map<String, Object> readMap(String jsonText) {
        try {
            return json.readValue(jsonText, Map.class);
        } catch (Exception e) {
            throw new IllegalStateException("数据库返回的 JSON 无法解析：" + jsonText, e);
        }
    }

    public static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }
}
