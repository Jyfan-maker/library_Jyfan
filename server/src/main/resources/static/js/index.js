/* 业务主页逻辑：图书 / 借阅 / 分类 / 统计 */
let currentUser = null;
let categories = [];
let booksCache = [];
let page = 1;
const pageSize = 10;

/* ---------- 初始化 ---------- */
(async function init() {
  try {
    const me = await get('/api/me');
    if (!handle(me)) return;
    currentUser = me.data;
    document.getElementById('welcome').textContent =
      '欢迎，' + (currentUser.realName || currentUser.username) + '（' + (currentUser.role === 'admin' ? '管理员' : '读者') + '）';
    await loadCategories();
    await loadBooks();
    await loadStat();
  } catch (e) {
    toast('初始化失败：' + e.message, true);
  }
})();

/* ---------- 页签切换 ---------- */
document.querySelectorAll('.nav-item').forEach(function (item) {
  item.addEventListener('click', function () {
    document.querySelectorAll('.nav-item').forEach(function (n) { n.classList.remove('active'); });
    item.classList.add('active');
    const p = item.dataset.page;
    document.querySelectorAll('.page').forEach(function (sec) { sec.hidden = true; });
    document.getElementById('page-' + p).hidden = false;
    if (p === 'borrow') loadBorrow();
    if (p === 'stat') loadStat();
  });
});

document.getElementById('logoutBtn').addEventListener('click', async function () {
  await post('/api/logout', {});
  location.href = 'login.html';
});

/* ---------- 分类 ---------- */
async function loadCategories() {
  const res = await post('/api/category/list', {});
  if (!handle(res)) return;
  categories = res.data || [];
  if (document.getElementById('categoryBody')) renderCategories();
}

function renderCategories() {
  const body = document.getElementById('categoryBody');
  body.innerHTML = categories.map(function (c) {
    return '<tr>' +
      '<td>' + c.id + '</td>' +
      '<td>' + escapeHtml(c.name) + '</td>' +
      '<td>' + escapeHtml(c.remark) + '</td>' +
      '<td><button class="btn-mini" onclick="editCategory(' + c.id + ')">编辑</button>' +
      '<button class="btn-mini danger" onclick="delCategory(' + c.id + ')">删除</button></td>' +
      '</tr>';
  }).join('') || '<tr><td colspan="4" class="empty">暂无分类</td></tr>';
}

document.getElementById('addCategoryBtn').addEventListener('click', function () {
  openModal('新增分类', [
    { key: 'name', label: '分类名称', type: 'text' },
    { key: 'remark', label: '说明', type: 'text' }
  ], {}, async function (data) {
    const res = await post('/api/category/save', data);
    if (handle(res)) { closeModal(); await loadCategories(); toast('保存成功'); }
  });
});

window.editCategory = async function (id) {
  const c = categories.find(function (x) { return x.id === id; });
  openModal('编辑分类', [
    { key: 'name', label: '分类名称', type: 'text' },
    { key: 'remark', label: '说明', type: 'text' }
  ], c, async function (data) {
    data.id = id;
    const res = await post('/api/category/save', data);
    if (handle(res)) { closeModal(); await loadCategories(); toast('保存成功'); }
  });
};

window.delCategory = async function (id) {
  if (!confirm('确定删除该分类？若分类下仍有图书将无法删除。')) return;
  const res = await post('/api/category/delete', { id: id });
  if (handle(res)) { toast('删除成功'); await loadCategories(); await loadBooks(); }
};

/* ---------- 图书 ---------- */
async function loadBooks(keyword) {
  const res = await post('/api/book/list', { keyword: keyword || '' });
  if (!handle(res)) return;
  booksCache = res.data || [];
  page = 1;
  renderBooks();
}

function renderBooks() {
  const start = (page - 1) * pageSize;
  const rows = booksCache.slice(start, start + pageSize);
  const body = document.getElementById('bookBody');
  body.innerHTML = rows.map(function (b) {
    const cat = (categories.find(function (c) { return c.id === b.categoryId; }) || {}).name || b.categoryName || '';
    return '<tr>' +
      '<td>' + b.id + '</td>' +
      '<td>' + escapeHtml(b.title) + '</td>' +
      '<td>' + escapeHtml(b.author) + '</td>' +
      '<td>' + escapeHtml(b.isbn) + '</td>' +
      '<td>' + escapeHtml(cat) + '</td>' +
      '<td>¥' + Number(b.price).toFixed(2) + '</td>' +
      '<td>' + b.stock + '</td>' +
      '<td><button class="btn-mini" onclick="editBook(' + b.id + ')">编辑</button>' +
      '<button class="btn-mini" onclick="borrowBook(' + b.id + ')">借出</button>' +
      '<button class="btn-mini danger" onclick="delBook(' + b.id + ')">删除</button></td>' +
      '</tr>';
  }).join('') || '<tr><td colspan="8" class="empty">暂无图书</td></tr>';

  const totalPages = Math.max(1, Math.ceil(booksCache.length / pageSize));
  document.getElementById('bookPager').innerHTML =
    '共 ' + booksCache.length + ' 本　第 ' + page + ' / ' + totalPages + ' 页 ' +
    '<button class="btn-mini" onclick="gotoPage(' + (page - 1) + ')" ' + (page <= 1 ? 'disabled' : '') + '>上一页</button>' +
    '<button class="btn-mini" onclick="gotoPage(' + (page + 1) + ')" ' + (page >= totalPages ? 'disabled' : '') + '>下一页</button>';
}

window.gotoPage = function (p) { page = p; renderBooks(); };

document.getElementById('searchBookBtn').addEventListener('click', function () {
  loadBooks(document.getElementById('bookKeyword').value.trim());
});
document.getElementById('resetBookBtn').addEventListener('click', function () {
  document.getElementById('bookKeyword').value = '';
  loadBooks();
});
document.getElementById('bookKeyword').addEventListener('keydown', function (e) {
  if (e.key === 'Enter') loadBooks(this.value.trim());
});

document.getElementById('addBookBtn').addEventListener('click', function () {
  const catOptions = categories.map(function (c) { return c.id + ':' + c.name; }).join(',');
  openModal('新增图书', [
    { key: 'title', label: '书名', type: 'text' },
    { key: 'author', label: '作者', type: 'text' },
    { key: 'isbn', label: 'ISBN', type: 'text' },
    { key: 'categoryId', label: '分类', type: 'select', options: catOptions },
    { key: 'price', label: '单价', type: 'number' },
    { key: 'stock', label: '库存', type: 'number' }
  ], { price: 0, stock: 0 }, async function (data) {
    const res = await post('/api/book/save', data);
    if (handle(res)) { closeModal(); await loadBooks(); await loadStat(); toast('保存成功'); }
  });
});

window.editBook = function (id) {
  const b = booksCache.find(function (x) { return x.id === id; });
  const catOptions = categories.map(function (c) { return c.id + ':' + c.name; }).join(',');
  openModal('编辑图书', [
    { key: 'title', label: '书名', type: 'text' },
    { key: 'author', label: '作者', type: 'text' },
    { key: 'isbn', label: 'ISBN', type: 'text' },
    { key: 'categoryId', label: '分类', type: 'select', options: catOptions },
    { key: 'price', label: '单价', type: 'number' },
    { key: 'stock', label: '库存', type: 'number' }
  ], b, async function (data) {
    data.id = id;
    const res = await post('/api/book/save', data);
    if (handle(res)) { closeModal(); await loadBooks(); await loadStat(); toast('保存成功'); }
  });
};

window.delBook = async function (id) {
  if (!confirm('确定删除这本图书？')) return;
  const res = await post('/api/book/delete', { id: id });
  if (handle(res)) { toast('删除成功'); await loadBooks(); await loadStat(); }
};

/* ---------- 借阅 ---------- */
async function loadBorrow() {
  const myOnly = document.getElementById('myOnly').checked;
  const url = myOnly ? '/api/borrow/my' : '/api/borrow/list';
  const res = await post(url, {});
  if (!handle(res)) return;
  const body = document.getElementById('borrowBody');
  body.innerHTML = (res.data || []).map(function (b) {
    const statusClass = b.status === '在借' ? 'badge-on' : 'badge-off';
    const returnBtn = b.status === '在借'
      ? '<button class="btn-mini" onclick="returnBorrow(' + b.id + ')">归还</button>' : '';
    return '<tr>' +
      '<td>' + b.id + '</td>' +
      '<td>' + escapeHtml(b.userName || '-') + '</td>' +
      '<td>' + escapeHtml(b.bookTitle || '-') + '</td>' +
      '<td>' + escapeHtml(b.borrowAt) + '</td>' +
      '<td>' + escapeHtml(b.returnAt || '-') + '</td>' +
      '<td><span class="badge ' + statusClass + '">' + escapeHtml(b.status) + '</span></td>' +
      '<td>¥' + Number(b.fine || 0).toFixed(2) + '</td>' +
      '<td>' + returnBtn + '</td>' +
      '</tr>';
  }).join('') || '<tr><td colspan="8" class="empty">暂无借阅记录</td></tr>';
}

document.getElementById('myOnly').addEventListener('change', loadBorrow);
document.getElementById('refreshBorrowBtn').addEventListener('click', loadBorrow);

document.getElementById('addBorrowBtn').addEventListener('click', function () {
  const bookOptions = booksCache.filter(function (b) { return b.stock > 0; })
    .map(function (b) { return b.id + ':' + b.title + '（库存' + b.stock + '）'; }).join(',');
  if (!bookOptions) { toast('当前没有可借的图书（库存均为 0）', true); return; }
  openModal('借书登记', [
    { key: 'bookId', label: '选择图书', type: 'select', options: bookOptions }
  ], {}, async function (data) {
    const res = await post('/api/borrow/borrow', { bookId: data.bookId });
    if (handle(res)) { closeModal(); await loadBorrow(); await loadBooks(); await loadStat(); toast('借书成功'); }
  });
});

window.returnBorrow = async function (id) {
  if (!confirm('确定归还这条借阅记录？')) return;
  const res = await post('/api/borrow/return', { id: id });
  if (handle(res)) { toast('归还成功'); await loadBorrow(); await loadBooks(); await loadStat(); }
};

window.borrowBook = function (bookId) {
  openModal('借书确认', [], {}, async function () {
    const res = await post('/api/borrow/borrow', { bookId: bookId });
    if (handle(res)) { closeModal(); await loadBooks(); await loadStat(); toast('借书成功'); }
  }, '确定借阅这本书吗？');
};

/* ---------- 统计 ---------- */
async function loadStat() {
  const res = await post('/api/book/stat', {});
  if (handle(res)) {
    document.getElementById('statTotal').textContent = res.data.total != null ? res.data.total : '-';
    document.getElementById('statStock').textContent = res.data.stock != null ? res.data.stock : '-';
    document.getElementById('statValue').textContent = res.data.value != null ? '¥' + Number(res.data.value).toFixed(2) : '-';
  }
  const cs = await post('/api/book/category-stat', {});
  if (handle(cs)) renderBars('categoryStat', cs.data || []);
  const bs = await post('/api/borrow/stat', {});
  if (handle(bs)) renderBars('borrowStat', bs.data || []);
}

function renderBars(elId, data) {
  const el = document.getElementById(elId);
  const max = Math.max(1, ...data.map(function (d) { return Number(d.cnt); }));
  el.innerHTML = data.map(function (d) {
    const w = Math.round(Number(d.cnt) / max * 100);
    return '<div class="bar-row"><span class="bar-name">' + escapeHtml(d.name) + '</span>' +
      '<div class="bar-track"><div class="bar-fill" style="width:' + w + '%"></div></div>' +
      '<span class="bar-num">' + d.cnt + '</span></div>';
  }).join('') || '<div class="empty">暂无数据</div>';
}

/* ---------- 通用弹窗 ---------- */
function openModal(title, fields, data, onSave, tip) {
  document.getElementById('modalTitle').textContent = title;
  const body = document.getElementById('modalBody');
  let html = '';
  if (tip) html += '<div class="modal-tip">' + escapeHtml(tip) + '</div>';
  html += fields.map(function (f) {
    const val = data && data[f.key] != null ? data[f.key] : '';
    if (f.type === 'select') {
      const opts = f.options.split(',').map(function (pair) {
        const idx = pair.indexOf(':');
        const v = idx < 0 ? pair : pair.substring(0, idx);
        const label = idx < 0 ? pair : pair.substring(idx + 1);
        return '<option value="' + escapeHtml(v) + '" ' + (String(val) === String(v) ? 'selected' : '') + '>' + escapeHtml(label) + '</option>';
      }).join('');
      return '<label>' + f.label + '</label><select data-key="' + f.key + '">' + opts + '</select>';
    }
    return '<label>' + f.label + '</label><input data-key="' + f.key + '" type="' + (f.type || 'text') + '" value="' + escapeHtml(val) + '">';
  }).join('');
  body.innerHTML = html;
  document.getElementById('modalMask').hidden = false;
  document.getElementById('modalSave').onclick = function () {
    const result = {};
    body.querySelectorAll('[data-key]').forEach(function (input) {
      result[input.dataset.key] = input.value.trim();
    });
    onSave(result);
  };
}
function closeModal() { document.getElementById('modalMask').hidden = true; }
document.getElementById('modalClose').addEventListener('click', closeModal);
document.getElementById('modalCancel').addEventListener('click', closeModal);
document.getElementById('modalMask').addEventListener('click', function (e) {
  if (e.target === this) closeModal();
});
