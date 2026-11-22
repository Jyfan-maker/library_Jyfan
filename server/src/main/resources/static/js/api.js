/* 前端与后端的唯一通道：fetch + JSON，不依赖任何框架 */

/** 统一 POST：请求体 JSON，响应体 JSON；同源凭证带上 session cookie */
async function post(url, data) {
  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json;charset=UTF-8' },
    credentials: 'same-origin',
    body: JSON.stringify(data || {})
  });
  if (!resp.ok) throw new Error('HTTP ' + resp.status);
  return await resp.json();
}

async function get(url) {
  const resp = await fetch(url, { credentials: 'same-origin' });
  if (!resp.ok) throw new Error('HTTP ' + resp.status);
  return await resp.json();
}

/** 业务失败统一提示；code=401 未登录直接跳登录页 */
function handle(res) {
  if (res.code === 401) {
    location.href = 'login.html';
    return false;
  }
  if (res.code !== 0) {
    toast(res.msg || '操作失败', true);
    return false;
  }
  return true;
}

let toastTimer = null;
function toast(text, isErr) {
  let el = document.querySelector('.toast');
  if (!el) {
    el = document.createElement('div');
    el.className = 'toast';
    document.body.appendChild(el);
  }
  el.textContent = text;
  el.className = 'toast show' + (isErr ? ' err' : '');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.className = 'toast'; }, 2200);
}

function escapeHtml(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
