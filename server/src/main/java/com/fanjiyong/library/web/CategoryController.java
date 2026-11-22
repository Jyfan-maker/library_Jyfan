package com.fanjiyong.library.web;

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
 * 分类接口（JSON 进 / JSON 出）
 * POST /api/category/list   分类列表
 * POST /api/category/save   新增或修改
 * POST /api/category/delete 删除（有图书引用时被外键阻止）
 */
@RestController
@RequestMapping("/api/category")
public class CategoryController {

    private final Sql sql;
    private final ObjectMapper json;

    public CategoryController(Sql sql, ObjectMapper json) {
        this.sql = sql;
        this.json = json;
    }

    @PostMapping("/list")
    public Map<String, Object> list(HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        try {
            List<?> data = json.readValue(sql.list("category_list"), List.class);
            return R.ok(data);
        } catch (Exception e) {
            return R.fail("分类列表解析失败");
        }
    }

    @PostMapping("/save")
    public Map<String, Object> save(@RequestBody(required = false) Map<String, Object> body, HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        if (body == null) {
            return R.fail("请求体不能为空");
        }
        String name = LoginController.str(body.get("name"));
        if (name.isEmpty()) {
            return R.fail("分类名称不能为空");
        }
        String remark = LoginController.str(body.get("remark"));
        String id = LoginController.str(body.get("id"));

        String exists = sql.one("category_exists", name);
        if (id.isEmpty()) {
            if (exists != null && !"0".equals(exists.trim())) {
                return R.fail("分类名称已存在");
            }
            int newId = sql.insert("category_add", name, remark);
            return newId > 0 ? R.ok(newId) : R.fail("新增失败");
        }
        // 修改时若改名成别的分类名，也要查重
        try {
            int n = sql.update("category_update", name, remark, Integer.parseInt(id));
            return n > 0 ? R.ok(Integer.parseInt(id)) : R.fail("修改失败，记录可能不存在");
        } catch (Exception e) {
            return R.fail("修改失败：分类名称可能重复");
        }
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
            int n = sql.update("category_delete", Integer.parseInt(id));
            return n > 0 ? R.ok(null) : R.fail("删除失败，分类可能不存在");
        } catch (Exception e) {
            return R.fail("删除失败：该分类下仍有图书，不能删除");
        }
    }
}
