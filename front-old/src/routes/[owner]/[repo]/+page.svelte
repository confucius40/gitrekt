<script>
  import { page } from '$app/stores';
  import { token } from '$lib/auth.js';
  import { getRepo, getTree, getCommits, getFile, getBlame, getIssues, getPulls } from '$lib/api.js';

  let tab = 'code';
  let repo = null;
  let nodes = [];
  let commits = [];
  let file = null;
  let blame = [];
  let loading = false;
  let err = null;
  let branch = 'main';

  async function loadRepo() {
    loading = true;
    try {
      const owner = $page.params.owner;
      const name = $page.params.repo;
      repo = await getRepo(owner, name);
    } catch (e) {
      err = e.message;
    }
    loading = false;
  }

  async function loadTree() {
    if (!repo) return;
    loading = true;
    try {
      nodes = await getTree($page.params.owner, $page.params.repo, branch);
    } catch (e) {
      err = e.message;
    }
    loading = false;
  }

  async function loadCommits() {
    if (!repo) return;
    loading = true;
    try {
      commits = await getCommits($page.params.owner, $page.params.repo, branch);
    } catch (e) {
      err = e.message;
    }
    loading = false;
  }

  async function viewFile(path) {
    if (!repo) return;
    loading = true;
    try {
      file = await getFile($page.params.owner, $page.params.repo, branch, path);
      blame = await getBlame($page.params.owner, $page.params.repo, branch, path);
    } catch (e) {
      err = e.message;
      file = null;
    }
    loading = false;
  }

  function cloneUrl() {
    return `ssh://git.yourforge.com/${$page.params.owner}/${$page.params.repo}.git`;
  }

  function selectTab(t) {
    tab = t;
    if (t === 'code' && nodes.length === 0) loadTree();
    if (t === 'commits' && commits.length === 0) loadCommits();
  }

  $: if ($page.params.repo) loadRepo();
  $: if (repo && tab === 'code') loadTree();
</script>

<div class="page">
  <nav class="crumb">
    <a href="/">explore</a>
    <span class="sep">/</span>
    <span class="item">{$page.params.owner}</span>
    <span class="sep">/</span>
    <span class="item">{$page.params.repo}</span>
  </nav>

  {#if loading && !repo}
    <div class="load">loading...</div>
  {:else if err}
    <div class="err">{err}</div>
  {:else if repo}
    <div class="repo-head">
      <h1>{repo.name}</h1>
      {#if repo.description}
        <p class="desc">{repo.description}</p>
      {/if}
      <div class="meta">
        {#if repo.is_private}
          <span class="badge">private</span>
        {:else}
          <span class="badge">public</span>
        {/if}
      </div>
    </div>

    <div class="ctrl">
      <select bind:value={branch} on:change={() => { nodes = []; commits = []; loadTree(); }}>
        <option value="main">main</option>
        <option value="master">master</option>
        <option value="dev">dev</option>
      </select>
      <input type="text" readonly value={cloneUrl()} class="clone-input" />
      <button on:click={() => navigator.clipboard.writeText(cloneUrl())}>copy</button>
    </div>

    <div class="tabs">
      <button class="tab" class:active={tab === 'code'} on:click={() => selectTab('code')}>
        code
      </button>
      <button class="tab" class:active={tab === 'commits'} on:click={() => selectTab('commits')}>
        commits
      </button>
      <button class="tab" class:active={tab === 'issues'} on:click={() => selectTab('issues')}>
        issues
      </button>
      <button class="tab" class:active={tab === 'pulls'} on:click={() => selectTab('pulls')}>
        pulls
      </button>
    </div>

    {#if tab === 'code'}
      {#if file}
        <div class="file-view">
          <div class="file-path">{file.path}</div>
          <div class="file-content">
            {#each file.lines as line, i}
              <div class="code-line">
                <span class="line-no">{i + 1}</span>
                <span class="blame">{blame[i]?.sha.slice(0, 7) || ''}</span>
                <code>{line}</code>
              </div>
            {/each}
          </div>
          <button on:click={() => { file = null; blame = []; }}>← back</button>
        </div>
      {:else}
        <div class="tree">
          {#each nodes as node}
            {#if node.type === 'tree'}
              <div class="tree-node" on:click={() => {}}>
                <span class="icon">📁</span>
                <span class="name">{node.name}/</span>
              </div>
            {:else}
              <div class="tree-node" on:click={() => viewFile(node.path)}>
                <span class="icon">📄</span>
                <span class="name">{node.name}</span>
              </div>
            {/if}
          {/each}
        </div>
      {/if}
    {:else if tab === 'commits'}
      <div class="commits">
        {#each commits as c}
          <div class="commit">
            <div class="commit-msg">{c.msg}</div>
            <div class="commit-meta">
              <span class="sha"><code>{c.sha.slice(0, 7)}</code></span>
              <span class="auth">{c.auth}</span>
              <span class="time">{c.time}</span>
            </div>
          </div>
        {/each}
      </div>
    {:else if tab === 'issues'}
      <div class="issues">
        <p>no issues yet</p>
      </div>
    {:else if tab === 'pulls'}
      <div class="pulls">
        <p>no pull requests yet</p>
      </div>
    {/if}
  {/if}
</div>

<style>
  .page {
    max-width: 1000px;
    margin: 0 auto;
    padding: 24px 16px;
  }

  .crumb {
    display: flex;
    align-items: center;
    font-size: 12px;
    color: var(--text-secondary);
    margin-bottom: 24px;
    font-family: monospace;
    gap: 4px;
  }

  .crumb a {
    color: var(--text-accent);
    text-decoration: none;
    cursor: pointer;
  }

  .crumb a:hover {
    text-decoration: underline;
  }

  .sep {
    color: var(--text-muted);
  }

  .load, .err {
    padding: 24px;
    text-align: center;
    color: var(--text-secondary);
  }

  .err {
    color: var(--text-danger);
  }

  .repo-head {
    margin-bottom: 24px;
  }

  .repo-head h1 {
    font-size: 28px;
    font-weight: 500;
    margin: 0 0 8px;
    font-family: monospace;
  }

  .desc {
    color: var(--text-secondary);
    font-size: 13px;
    margin: 0 0 12px;
  }

  .meta {
    display: flex;
    gap: 8px;
  }

  .badge {
    display: inline-block;
    padding: 4px 8px;
    font-size: 11px;
    border: 1px solid var(--border);
    border-radius: 3px;
    color: var(--text-secondary);
    font-weight: 500;
  }

  .ctrl {
    display: flex;
    gap: 8px;
    margin-bottom: 24px;
    align-items: center;
  }

  select {
    padding: 6px 8px;
    font-size: 12px;
    border: 1px solid var(--border);
    background: var(--surface-1);
    color: var(--text-primary);
    border-radius: 3px;
    font-family: monospace;
    cursor: pointer;
  }

  select:hover {
    border-color: var(--border-strong);
  }

  .clone-input {
    flex: 1;
    padding: 6px 8px;
    font-size: 11px;
    border: 1px solid var(--border);
    background: var(--surface-1);
    color: var(--text-secondary);
    font-family: monospace;
    border-radius: 3px;
  }

  .clone-input:focus {
    outline: none;
    border-color: var(--text-accent);
  }

  button {
    padding: 6px 10px;
    font-size: 11px;
    border: 1px solid var(--border);
    background: var(--surface-1);
    color: var(--text-primary);
    cursor: pointer;
    border-radius: 3px;
    font-family: monospace;
  }

  button:hover {
    background: var(--surface-2);
    border-color: var(--border-strong);
  }

  .tabs {
    display: flex;
    gap: 0;
    border-bottom: 1px solid var(--border);
    margin-bottom: 24px;
  }

  .tab {
    padding: 10px 16px;
    font-size: 12px;
    color: var(--text-secondary);
    text-decoration: none;
    border: none;
    border-bottom: 2px solid transparent;
    background: transparent;
    cursor: pointer;
    font-family: monospace;
  }

  .tab:hover {
    color: var(--text-primary);
  }

  .tab.active {
    color: var(--text-primary);
    border-bottom-color: var(--text-accent);
  }

  .tree {
    border: 1px solid var(--border);
    border-radius: 4px;
    background: var(--surface-1);
    margin-bottom: 24px;
  }

  .tree-node {
    padding: 8px 12px;
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: center;
    font-family: monospace;
    font-size: 13px;
    cursor: pointer;
    user-select: none;
  }

  .tree-node:last-child {
    border-bottom: none;
  }

  .tree-node:hover {
    background: var(--surface-2);
  }

  .icon {
    margin-right: 8px;
    width: 16px;
  }

  .name {
    color: var(--text-primary);
  }

  .file-view {
    border: 1px solid var(--border);
    border-radius: 4px;
    background: var(--surface-1);
    overflow-x: auto;
  }

  .file-path {
    padding: 10px 12px;
    border-bottom: 1px solid var(--border);
    font-size: 12px;
    font-family: monospace;
    color: var(--text-secondary);
    font-weight: 500;
  }

  .file-content {
    font-family: monospace;
    font-size: 12px;
    line-height: 1.6;
  }

  .code-line {
    display: flex;
    border-bottom: 1px solid var(--border);
    padding: 0;
  }

  .code-line:hover {
    background: var(--surface-2);
  }

  .line-no {
    display: inline-block;
    width: 40px;
    padding: 4px 8px;
    text-align: right;
    background: var(--surface-2);
    color: var(--text-muted);
    user-select: none;
    border-right: 1px solid var(--border);
  }

  .blame {
    display: inline-block;
    width: 50px;
    padding: 4px 8px;
    color: var(--text-muted);
    font-size: 10px;
    user-select: none;
    border-right: 1px solid var(--border);
  }

  code {
    padding: 4px 8px;
    flex: 1;
    color: var(--text-primary);
    white-space: pre;
    overflow-x: auto;
  }

  .commits {
    border: 1px solid var(--border);
    border-radius: 4px;
    background: var(--surface-1);
  }

  .commit {
    padding: 12px;
    border-bottom: 1px solid var(--border);
    cursor: pointer;
  }

  .commit:last-child {
    border-bottom: none;
  }

  .commit:hover {
    background: var(--surface-2);
  }

  .commit-msg {
    font-size: 13px;
    color: var(--text-primary);
    margin-bottom: 6px;
    font-weight: 500;
  }

  .commit-meta {
    display: flex;
    gap: 16px;
    font-size: 11px;
    color: var(--text-muted);
  }

  .sha code {
    background: transparent;
    padding: 0;
    color: var(--text-accent);
  }

  .issues, .pulls {
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 24px;
    text-align: center;
    color: var(--text-secondary);
  }
</style>
