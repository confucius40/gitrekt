const API = 'http://localhost:3000';

export async function get(path, token) {
  const h = token ? { 'Authorization': `Bearer ${token}` } : {};
  const res = await fetch(`${API}${path}`, { headers: h });
  if (!res.ok) throw new Error(`${res.status}`);
  return res.json();
}

export async function post(path, body, token) {
  const h = { 'Content-Type': 'application/json' };
  if (token) h['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${API}${path}`, {
    method: 'POST',
    headers: h,
    body: JSON.stringify(body)
  });
  if (!res.ok) throw new Error(`${res.status}`);
  return res.json();
}

export async function del(path, token) {
  const h = token ? { 'Authorization': `Bearer ${token}` } : {};
  const res = await fetch(`${API}${path}`, {
    method: 'DELETE',
    headers: h
  });
  if (!res.ok) throw new Error(`${res.status}`);
  return res.json();
}

export async function getRepo(owner, name) {
  return get(`/repos/${owner}/${name}`);
}

export async function getTree(owner, name, ref) {
  return get(`/repos/${owner}/${name}/tree/${ref}`);
}

export async function getCommits(owner, name, ref) {
  return get(`/repos/${owner}/${name}/commits/${ref}`);
}

export async function getFile(owner, name, ref, path) {
  return get(`/repos/${owner}/${name}/file/${ref}/${path}`);
}

export async function getBlame(owner, name, ref, path) {
  return get(`/repos/${owner}/${name}/blame/${ref}/${path}`);
}

export async function getIssues(owner, name) {
  return get(`/repos/${owner}/${name}/issues`);
}

export async function getPulls(owner, name) {
  return get(`/repos/${owner}/${name}/pulls`);
}

export async function searchRepos(q) {
  return get(`/repos/search?q=${encodeURIComponent(q)}`);
}

export async function getIdent(name) {
  return get(`/identities/${name}`);
}

export async function genToken(token) {
  return post(`/admin/tokens`, {}, token);
}

export async function listTokens(token) {
  return get(`/admin/tokens`, token);
}

export async function revokeToken(id, token) {
  return del(`/admin/tokens/${id}`, token);
}

export function setToken(tk) {
  localStorage.setItem('git-token', tk);
}

export function getToken() {
  return localStorage.getItem('git-token');
}

export function clearToken() {
  localStorage.removeItem('git-token');
}
