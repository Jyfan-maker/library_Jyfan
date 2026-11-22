package com.fanjiyong.library.web;

import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fanjiyong.library.comm.R;
import com.fanjiyong.library.comm.Sql;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 借阅接口（JSON 进 / JSON 出）
 * POST /api/borrow/list       借阅记录列表
 * POST /api/borrow/my         当前读者的借阅记录
 * POST /api/borrow/borrow     借书（事务：新增记录 + 库存减一）
 * POST /api/borrow/return     还书（事务：更新状态 + 库存加一）
 * POST /api/borrow/stat       按分类统计借阅次数
 */
@RestController
@RequestMapping("/api/borrow")
public class BorrowController {

    private final Sql sql;
    private final ObjectMapper json;

    public BorrowController(Sql sql, ObjectMapper json) {
        this.sql = sql;
        this.json = json;
    }

    @PostMapping("/list")
    public Map<String, Object> list(HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        return R.ok(readList(sql.list("borrow_list")));
    }

    /** 普通读者只能看自己的借阅记录；管理员可看全部 */
    @PostMapping("/my")
    public Map<String, Object> my(HttpSession session) {
        Object uid = session.getAttribute("uid");
        if (uid == null) {
            return R.noLogin();
        }
        Object role = session.getAttribute("role");
        if ("admin".equals(role)) {
            return R.ok(readList(sql.list("borrow_list")));
        }
        return R.ok(readList(sql.list("borrow_by_user", uid)));
    }

    /**
     * 借书：事务保证"新增借阅记录"与"库存减一"同时成功或同时回滚。
     * 这是任务书的加分项（事务处理）。
     */
    @PostMapping("/borrow")
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> borrow(@RequestBody(required = false) Map<String, Object> body, HttpSession session) {
        Object uid = session.getAttribute("uid");
        if (uid == null) {
            return R.noLogin();
        }
        int bookId = body == null ? 0 : integer(body.get("bookId"));
        if (bookId <= 0) {
            return R.fail("缺少图书编号");
        }

        // 先检查该读者是否已借这本书且未归还
        String active = sql.one("borrow_active", uid, bookId);
        if (active != null && !"0".equals(active.trim())) {
            return R.fail("你已经借阅了这本书且尚未归还");
        }

        // 库存减一：仅当 stock > 0 时才会更新，返回 0 表示库存不足
        int dec = sql.update("book_stock_dec", bookId);
        if (dec == 0) {
            return R.fail("库存不足，无法借阅");
        }
        // 新增借阅记录
        int id = sql.insert("borrow_add", uid, bookId);
        if (id <= 0) {
            throw new RuntimeException("借书记录新增失败，事务回滚");
        }
        return R.ok(id);
    }

    /** 还书：事务保证"状态改为已还"与"库存加一"原子性 */
    @PostMapping("/return")
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> returnBook(@RequestBody(required = false) Map<String, Object> body, HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        int borrowId = body == null ? 0 : integer(body.get("id"));
        if (borrowId <= 0) {
            return R.fail("缺少借阅编号");
        }
        // 借书记录里带 book_id，先从列表 SQL 找对应图书（这里用一条辅助查询）
        Integer bookId = findBookIdByBorrow(borrowId);
        if (bookId == null) {
            return R.fail("借阅记录不存在");
        }
        int n = sql.update("borrow_return", borrowId);
        if (n == 0) {
            return R.fail("该记录已归还或不存在");
        }
        sql.update("book_stock_inc", bookId);
        return R.ok(null);
    }

    @PostMapping("/stat")
    public Map<String, Object> stat(HttpSession session) {
        if (session.getAttribute("uid") == null) {
            return R.noLogin();
        }
        return R.ok(readList(sql.list("borrow_stat")));
    }

    /** 根据借阅编号查图书编号（供还书时加库存用） */
    private Integer findBookIdByBorrow(int borrowId) {
        try {
            String jsonText = sql.one("borrow_book_of", borrowId);
            if (jsonText == null) {
                return null;
            }
            Map<?, ?> m = json.readValue(jsonText, Map.class);
            Object v = m.get("bookId");
            return v == null ? null : ((Number) v).intValue();
        } catch (Exception e) {
            return null;
        }
    }

    private List<?> readList(String jsonText) {
        try {
            return json.readValue(jsonText, List.class);
        } catch (Exception e) {
            throw new IllegalStateException("数据库返回的 JSON 无法解析：" + jsonText, e);
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
