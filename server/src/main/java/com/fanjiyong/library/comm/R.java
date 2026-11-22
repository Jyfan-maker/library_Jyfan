package com.fanjiyong.library.comm;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 统一返回格式：{ "code": 0, "msg": "ok", "data": ... }
 * code = 0 成功，1 业务失败，401 未登录/会话过期。
 */
public final class R {

    private R() {
    }

    public static Map<String, Object> ok(Object data) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", 0);
        m.put("msg", "ok");
        m.put("data", data);
        return m;
    }

    public static Map<String, Object> fail(String msg) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", 1);
        m.put("msg", msg);
        m.put("data", null);
        return m;
    }

    public static Map<String, Object> noLogin() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", 401);
        m.put("msg", "未登录或会话已过期，请重新登录");
        m.put("data", null);
        return m;
    }
}
