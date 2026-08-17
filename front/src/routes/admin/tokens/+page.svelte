<script>
  import { token } from '$lib/auth.js';
  import { genToken, listTokens, revokeToken } from '$lib/api.js';

  let tokens = [];
  let loading = false;
  let newToken = null;
  let err = null;

  async function load() {
    if (!$token) return;

    loading = true;
    err = null;

    try {
      tokens = await listTokens($token);
    } catch (e) {
      err = e?.message ?? 'Failed to load tokens';
    } finally {
      loading = false;
    }
  }

  async function gen() {
    if (!$token) return;

    loading = true;
    err = null;

    try {
      newToken = await genToken($token);
      await load();
    } catch (e) {
      err = e?.message ?? 'Failed to generate token';
    } finally {
      loading = false;
    }
  }

  async function revoke(id) {
    if (!$token) return;

    err = null;

    try {
      await revokeToken(id, $token);
      await load();
    } catch (e) {
      err = e?.message ?? 'Failed to revoke token';
    }
  }

  $effect(() => {
    if ($token) {
      load();
    }
  });
</script>

<div class="page">
  <header class="head">
    <h1>Admin panel</h1>
    <span class="sub">/admin/tokens</span>
  </header>

  {#if !$token}
    <div class="box">
      <p>No token. Can't access.</p>
    </div>
  {:else}
    <div class="box">
      <h2>Issue new token</h2>

      <button onclick={gen} disabled={loading}>
        {loading ? 'Generating...' : 'Generate'}
      </button>

      {#if newToken}
        <div class="token-display">
          <code>{newToken}</code>
          <small>Save this token somewhere safe. It will not be shown again.</small>
        </div>
      {/if}
    </div>

    {#if err}
      <div class="err">{err}</div>
    {/if}

    <table class="tokens">
      <thead>
        <tr>
          <th>ID</th>
          <th>Hash</th>
          <th>Identity</th>
          <th>Scope</th>
          <th>Created</th>
          <th>Revoked</th>
          <th>Actions</th>
        </tr>
      </thead>

      <tbody>
        {#if tokens.length === 0}
          <tr>
            <td colspan="7" class="empty">
              No tokens found.
            </td>
          </tr>
        {:else}
          {#each tokens as t}
            <tr>
              <td>{t.id}</td>

              <td>
                <code>
                  {t.token_hash ? `${t.token_hash.slice(0, 8)}...` : '-'}
                </code>
              </td>

              <td>{t.identity_id}</td>

              <td>{t.scope}</td>

              <td>{t.created_at}</td>

              <td>{t.revoked_at || '-'}</td>

              <td class="actions">
                {#if !t.revoked_at}
                  <button
                    onclick={() => revoke(t.id)}
                    class="danger"
                  >
                    Revoke
                  </button>
                {:else}
                  <span class="revoked">Revoked</span>
                {/if}
              </td>
            </tr>
          {/each}
        {/if}
      </tbody>
    </table>
  {/if}
</div>

<style>
  .page {
    max-width: 900px;
    margin: 0 auto;
    padding: 24px 16px;
  }

  .head {
    margin-bottom: 32px;
  }

  .head h1 {
    font-size: 20px;
    font-weight: 500;
    margin: 0 0 8px;
  }

  .sub {
    font-size: 12px;
    color: var(--text-secondary);
    font-family: monospace;
  }

  .box {
    background: var(--surface-1);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 16px;
    margin-bottom: 24px;
  }

  .box h2 {
    font-size: 14px;
    font-weight: 500;
    margin: 0 0 16px;
  }

  button {
    padding: 8px 12px;
    font-size: 12px;
    border: 1px solid var(--border);
    background: var(--surface-2);
    color: var(--text-primary);
    cursor: pointer;
    border-radius: 4px;
    font-family: monospace;
  }

  button:hover:not(:disabled) {
    background: var(--surface-1);
    border-color: var(--border-strong);
  }

  button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  button.danger {
    color: var(--text-danger);
  }

  button.danger:hover:not(:disabled) {
    background: var(--bg-danger);
  }

  .token-display {
    background: var(--surface-2);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 12px;
    margin-top: 12px;
    font-family: monospace;
    font-size: 12px;
    word-break: break-all;
  }

  .token-display code {
    display: block;
    margin-bottom: 6px;
    color: var(--text-accent);
  }

  .token-display small {
    display: block;
    color: var(--text-muted);
    font-family: sans-serif;
    font-size: 11px;
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

  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 12px;
    border: 1px solid var(--border);
    border-radius: 4px;
    overflow: hidden;
  }

  th,
  td {
    padding: 10px 12px;
    text-align: left;
    border-bottom: 1px solid var(--border);
  }

  tbody tr:last-child td {
    border-bottom: none;
  }

  th {
    background: var(--surface-1);
    font-weight: 500;
    color: var(--text-primary);
  }

  td {
    color: var(--text-primary);
  }

  .actions {
    text-align: right;
  }

  .revoked {
    color: var(--text-muted);
    font-size: 11px;
  }

  .empty {
    text-align: center;
    color: var(--text-muted);
    padding: 24px;
  }

  code {
    background: var(--surface-2);
    padding: 2px 6px;
    border-radius: 3px;
    font-size: 11px;
  }

  .token-display code {
    background: transparent;
    padding: 0;
  }
</style>
