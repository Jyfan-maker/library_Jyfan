package com.fanjiyong.library.web;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fanjiyong.library.comm.R;
import com.fanjiyong.library.comm.Sql;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 图书接口（JSON 进 / JSON 出）
 * POST /api/book/list    列表（keyword 模糊搜索书名/作者/ISBN）
 * POST /api/book/save    新增或修改（无 id 新增，有 id 修改）
 * POST /api/book/delete  删除
 * POST /api/book/stat    统计（总数、库存总量、库存总价值）
 */
@RestController
@RequestMapping("/api/book")
public class BookController {

    private final Sql sql;
    private final ObjectMapper json;

    public BookController(Sql sql, ObjectMapper json) {
        this.sql = sql;
        this.json = json;
    }

    @PostMapping("/list")
    public Map<String, Object> list(@RequestBody(required = false) Map<String, Object> body, HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        String keyword = body == null ? "" : LoginController.str(body.get("keyword"));
        String data;
        if (keyword.isEmpty()) {
            data = sql.list("book_list");
        } else {
            String like = "%" + keyword + "%";
            data = sql.list("book_search", like, like, like);
        }
        return R.ok(readList(data));
    }

    @PostMapping("/save")
    public Map<String, Object> save(@RequestBody(required = false) Map<String, Object> body, HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        if (body == null) {
            return R.fail("请求体不能为空");
        }
        String title = LoginController.str(body.get("title"));
        if (title.isEmpty()) {
            return R.fail("书名不能为空");
        }
        String author = LoginController.str(body.get("author"));
        String isbn = LoginController.str(body.get("isbn"));
        int categoryId = integer(body.get("categoryId"));
        if (categoryId <= 0) {
            return R.fail("请选择图书分类");
        }
        BigDecimal price = decimal(body.get("price"));
        int stock = integer(body.get("stock"));
        if (price.signum() < 0 || stock < 0) {
            return R.fail("价格和库存不能为负数");
        }

        String id = LoginController.str(body.get("id"));
        if (id.isEmpty()) {
            int newId = sql.insert("book_add", title, author, isbn, categoryId, price, stock);
            return newId > 0 ? R.ok(newId) : R.fail("新增失败，请检查分类是否存在");
        }
        int n = sql.update("book_update", title, author, isbn, categoryId, price, stock, Integer.parseInt(id));
        return n > 0 ? R.ok(Integer.parseInt(id)) : R.fail("修改失败，记录可能已被删除");
    }

    @PostMapping("/delete")
    public Map<String, Object> delete(@RequestBody(required = false) Map<String, Object> body, HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        String id = body == null ? "" : LoginController.str(body.get("id"));
        if (id.isEmpty()) {
            return R.fail("缺少 id");
        }
        try {
            int n = sql.update("book_delete", Integer.parseInt(id));
            return n > 0 ? R.ok(null) : R.fail("删除失败，记录可能不存在");
        } catch (Exception e) {
            // 外键约束会阻止删除仍有借阅记录的图书
            return R.fail("删除失败：该图书存在借阅记录，不能删除");
        }
    }

    @PostMapping("/stat")
    public Map<String, Object> stat(HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        String data = sql.one("book_stat");
        if (data == null) {
            return R.ok(Collections.emptyMap());
        }
        try {
            return R.ok(json.readValue(data, Map.class));
        } catch (Exception e) {
            return R.fail("统计结果解析失败");
        }
    }

    @PostMapping("/category-stat")
    public Map<String, Object> categoryStat(HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        return R.ok(readList(sql.list("category_stat")));
    }

    private List<?> readList(String jsonText) {
        try {
            return json.readValue(jsonText, List.class);
        } catch (Exception e) {
            throw new IllegalStateException("数据库返回的 JSON 无法解析：" + jsonText, e);
        }
    }

    private static BigDecimal decimal(Object o) {
        if (o == null || String.valueOf(o).trim().isEmpty()) {
            return BigDecimal.ZERO;
        }
        try {
            return new BigDecimal(String.valueOf(o).trim());
        } catch (NumberFormatException e) {
            return BigDecimal.ZERO;
        }
    }

    private static int integer(Object o) {
        if (o == null || String.valueOf(o).trim().isEmpty()) {
            return 0;
        }
        try {
            return (int) Double.parseDouble(String.valueOf(o).trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}
