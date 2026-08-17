<script>
  import { token } from '$lib/auth.js';
  import { searchRepos } from '$lib/api.js';

  let repos = [];
  let loading = false;
  let err = null;
  let q = '';

  async function search() {
    if (!q.trim()) {
      repos = [];
      return;
    }
    loading = true;
    try {
      repos = await searchRepos(q);
    } catch (e) {
      err = e.message;
    }
    loading = false;
  }

  function go(owner, name) {
    window.location.href = `/${owner}/${name}`;
  }

  function cap(s) {
    return s.charAt(0).toUpperCase() + s.slice(1);
  }
</script>

<div class="page">
  <div class="head">
    <h1>Explore</h1>
    <p class="sub">find repos</p>
  </div>

  <div class="search-box">
    <input
      type="text"
      placeholder="search repos, users, orgs..."
      bind:value={q}
      on:keydown={(e) => e.key === 'Enter' && search()}
      class="search-input"
    />
    <button on:click={search} disabled={loading}>search</button>
  </div>

  {#if err}
    <div class="err">{err}</div>
  {/if}

  {#if loading}
    <div class="load">searching...</div>
  {:else if repos.length}
    <div class="grid">
      {#each repos as repo}
        <div class="card" on:click={() => go(repo.owner, repo.name)}>
          <h3>{repo.owner}/{repo.name}</h3>
          {#if repo.description}
            <p class="desc">{repo.description}</p>
          {/if}
          <div class="card-meta">
            {#if repo.is_private}
              <span class="badge">private</span>
            {:else}
              <span class="badge">public</span>
            {/if}
          </div>
        </div>
      {/each}
    </div>
  {:else if q}
    <div class="empty">no repos found</div>
  {:else}
    <div class="empty">start typing to search</div>
  {/if}
</div>

<style>
  .page {
    max-width: 900px;
    margin: 0 auto;
    padding: 24px 16px;
  }

  .head {
    text-align: center;
    margin-bottom: 32px;
  }

  .head h1 {
    font-size: 28px;
    font-weight: 500;
    margin: 0 0 8px;
  }

  .sub {
    color: var(--text-secondary);
    font-size: 13px;
    margin: 0;
  }

  .search-box {
    display: flex;
    gap: 8px;
    margin-bottom: 32px;
  }

  .search-input {
    flex: 1;
    padding: 10px 12px;
    font-size: 13px;
    border: 1px solid var(--border);
    background: var(--surface-1);
    color: var(--text-primary);
    border-radius: 4px;
    font-family: monospace;
  }

  .search-input:focus {
    outline: none;
    border-color: var(--text-accent);
  }

  button {
    padding: 10px 16px;
    font-size: 12px;
    border: 1px solid var(--border);
    background: var(--surface-1);
    color: var(--text-primary);
    cursor: pointer;
    border-radius: 4px;
    font-family: monospace;
  }

  button:hover:not(:disabled) {
    background: var(--surface-2);
  }

  button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .err {
    background: var(--bg-danger);
    border: 1px solid var(--border-danger);
    color: var(--text-danger);
    padding: 12px;
    border-radius: 4px;
    margin-bottom: 24px;
    font-size: 12px;
  }

  .load, .empty {
    text-align: center;
    padding: 32px 16px;
    color: var(--text-secondary);
    font-size: 13px;
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 16px;
  }

  .card {
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 16px;
    background: var(--surface-1);
    cursor: pointer;
    transition: background 0.15s;
  }

  .card:hover {
    background: var(--surface-2);
  }

  .card h3 {
    font-size: 14px;
    font-weight: 500;
    margin: 0 0 8px;
    color: var(--text-primary);
    font-family: monospace;
  }

  .desc {
    font-size: 12px;
    color: var(--text-secondary);
    margin: 0 0 12px;
    line-height: 1.5;
  }

  .card-meta {
    display: flex;
    gap: 8px;
  }

  .badge {
    display: inline-block;
    padding: 4px 8px;
    font-size: 10px;
    border: 1px solid var(--border);
    border-radius: 2px;
    color: var(--text-secondary);
    font-weight: 500;
  }
</style>
