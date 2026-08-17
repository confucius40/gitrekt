<script>
  import { page } from '$app/stores';
  import { token } from '$lib/auth.js';
  import { getIssues, getPulls, post } from '$lib/api.js';

  let tab = 'issues';
  let issues = [];
  let pulls = [];
  let loading = false;
  let err = null;
  let form = null;
  let title = '';
  let body = '';

  async function loadIssues() {
    loading = true;
    try {
      issues = await getIssues($page.params.owner, $page.params.repo);
    } catch (e) {
      err = e.message;
    }
    loading = false;
  }

  async function loadPulls() {
    loading = true;
    try {
      pulls = await getPulls($page.params.owner, $page.params.repo);
    } catch (e) {
      err = e.message;
    }
    loading = false;
  }

  async function create() {
    if (!title.trim()) {
      err = 'title required';
      return;
    }
    loading = true;
    try {
      await post(
        `/repos/${$page.params.owner}/${$page.params.repo}/issues`,
        { title, body },
        $token
      );
      title = '';
      body = '';
      form = null;
      loadIssues();
    } catch (e) {
      err = e.message;
    }
    loading = false;
  }

  $: if (tab === 'issues') loadIssues();
  $: if (tab === 'pulls') loadPulls();
</script>

<div class="page">
  <div class="head">
    <h1>Issues & Pull Requests</h1>
  </div>

  <div class="tabs">
    <button class="tab" class:active={tab === 'issues'} on:click={() => (tab = 'issues')}>
      issues ({issues.length})
    </button>
    <button class="tab" class:active={tab === 'pulls'} on:click={() => (tab = 'pulls')}>
      pull requests ({pulls.length})
    </button>
  </div>

  {#if err}
    <div class="err">{err}</div>
  {/if}

  {#if tab === 'issues'}
    <button class="new-btn" on:click={() => (form = 'issue')}>+ new issue</button>

    {#if form === 'issue'}
      <div class="form">
        <input
          type="text"
          placeholder="title"
          bind:value={title}
          class="input"
        />
        <textarea placeholder="description" bind:value={body} class="textarea" />
        <div class="form-btns">
          <button on:click={create} disabled={loading} class="btn-primary">create</button>
          <button on:click={() => { form = null; title = ''; body = ''; }}>cancel</button>
        </div>
      </div>
    {/if}

    <div class="list">
      {#each issues as issue}
        <div class="item">
          <div class="item-title">{issue.is_title}</div>
          <div class="item-meta">
            <span class="status" class:open={issue.is_status === 'open'} class:closed={issue.is_status === 'closed'}>
              {issue.is_status}
            </span>
            <span class="auth">by {issue.is_auth}</span>
          </div>
        </div>
      {/each}
    </div>
  {:else if tab === 'pulls'}
    <button class="new-btn" on:click={() => (form = 'pr')}>+ new pull request</button>

    <div class="list">
      {#each pulls as pr}
        <div class="item">
          <div class="item-title">{pr.pr_title}</div>
          <div class="item-meta">
            <span class="status" class:open={pr.pr_status === 'open'} class:merged={pr.pr_status === 'merged'}>
              {pr.pr_status}
            </span>
            <span class="auth">by {pr.pr_auth}</span>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .page {
    max-width: 900px;
    margin: 0 auto;
    padding: 24px 16px;
  }

  .head {
    margin-bottom: 24px;
  }

  .head h1 {
    font-size: 24px;
    font-weight: 500;
    margin: 0;
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

  .err {
    background: var(--bg-danger);
    border: 1px solid var(--border-danger);
    color: var(--text-danger);
    padding: 12px;
    border-radius: 4px;
    margin-bottom: 16px;
    font-size: 12px;
  }

  .new-btn {
    padding: 8px 12px;
    font-size: 12px;
    border: 1px solid var(--border);
    background: var(--surface-1);
    color: var(--text-primary);
    cursor: pointer;
    border-radius: 4px;
    font-family: monospace;
    margin-bottom: 24px;
  }

  .new-btn:hover {
    background: var(--surface-2);
  }

  .form {
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 16px;
    margin-bottom: 24px;
    background: var(--surface-1);
  }

  .input, .textarea {
    width: 100%;
    padding: 8px 12px;
    font-size: 12px;
    border: 1px solid var(--border);
    background: var(--surface-2);
    color: var(--text-primary);
    border-radius: 4px;
    font-family: monospace;
    margin-bottom: 12px;
    box-sizing: border-box;
  }

  .input:focus, .textarea:focus {
    outline: none;
    border-color: var(--text-accent);
  }

  .textarea {
    resize: vertical;
    min-height: 120px;
  }

  .form-btns {
    display: flex;
    gap: 8px;
  }

  .btn-primary {
    padding: 8px 12px;
    font-size: 12px;
    border: 1px solid var(--text-accent);
    background: var(--text-accent);
    color: #fff;
    cursor: pointer;
    border-radius: 4px;
    font-family: monospace;
  }

  .btn-primary:hover {
    opacity: 0.9;
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .list {
    border: 1px solid var(--border);
    border-radius: 4px;
    background: var(--surface-1);
  }

  .item {
    padding: 12px;
    border-bottom: 1px solid var(--border);
    cursor: pointer;
  }

  .item:last-child {
    border-bottom: none;
  }

  .item:hover {
    background: var(--surface-2);
  }

  .item-title {
    font-size: 13px;
    font-weight: 500;
    color: var(--text-primary);
    margin-bottom: 6px;
  }

  .item-meta {
    display: flex;
    gap: 12px;
    font-size: 11px;
    color: var(--text-secondary);
  }

  .status {
    display: inline-block;
    padding: 2px 6px;
    border-radius: 2px;
    font-weight: 500;
    border: 1px solid var(--border);
  }

  .status.open {
    color: var(--text-success);
    border-color: var(--text-success);
  }

  .status.closed {
    color: var(--text-danger);
    border-color: var(--text-danger);
  }

  .status.merged {
    color: #9966ff;
    border-color: #9966ff;
  }
</style>
