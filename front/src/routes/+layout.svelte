<script>
  import { token } from '$lib/auth.js';

  let dark = false;

  function toggle() {
    dark = !dark;
  }

  function login() {
    const tk = prompt('Token?');
    if (tk) {
      token.login(tk);
    }
  }

  function logout() {
    token.logout();
  }
</script>

<div class="app" data-dark={dark}>
  <header class="header">
    <a href="/" class="logo">GitRekt</a>
    <nav class="nav">
      <a href="/explore">explore</a>
      {#if $token}
        <a href="/admin/tokens">admin</a>
        <button on:click={logout} class="btn-sm">logout</button>
      {:else}
        <button on:click={login} class="btn-sm">login</button>
      {/if}
      <button on:click={toggle} class="btn-sm">theme</button>
    </nav>
  </header>

  <main class="content">
    <slot />
  </main>

  <footer class="footer">
    <p>GitRekt 0.1 | no accounts, only tokens</p>
  </footer>
</div>

<style>
  :global(:root) {
    --surface-0: #f5f5f0;
    --surface-1: #efefea;
    --surface-2: #e8e8e3;
    --text-primary: #1a1a18;
    --text-secondary: #666;
    --text-muted: #999;
    --text-accent: #0066cc;
    --text-danger: #cc2211;
    --text-success: #009900;
    --border: #ddd;
    --border-strong: #bbb;
    --bg-danger: #ffe8e8;
    --bg-success: #e8f5e9;
  }

  :global([data-dark="true"]) {
    --surface-0: #1a1a18;
    --surface-1: #2a2a25;
    --surface-2: #353530;
    --text-primary: #e8e8e3;
    --text-secondary: #999;
    --text-muted: #666;
    --text-accent: #66bbff;
    --text-danger: #ff6655;
    --border: #444;
    --border-strong: #666;
    --bg-danger: #4a2222;
    --bg-success: #224422;
  }

  .app {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
    background: var(--surface-0);
    color: var(--text-primary);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "SF Mono", "Menlo", monospace;
    font-size: 14px;
    line-height: 1.5;
  }

  .header {
    background: var(--surface-2);
    border-bottom: 1px solid var(--border);
    padding: 12px 16px;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .logo {
    font-size: 16px;
    font-weight: 600;
    letter-spacing: 1px;
    text-decoration: none;
    color: var(--text-primary);
  }

  .logo:hover {
    opacity: 0.8;
  }

  .nav {
    display: flex;
    gap: 16px;
    align-items: center;
  }

  .nav a {
    text-decoration: none;
    color: var(--text-secondary);
    font-size: 12px;
  }

  .nav a:hover {
    color: var(--text-primary);
  }

  .btn-sm {
    padding: 6px 10px;
    font-size: 11px;
    border: 1px solid var(--border);
    background: var(--surface-1);
    color: var(--text-primary);
    cursor: pointer;
    border-radius: 3px;
    font-family: inherit;
  }

  .btn-sm:hover {
    background: var(--surface-2);
  }

  .content {
    flex: 1;
  }

  .footer {
    background: var(--surface-1);
    border-top: 1px solid var(--border);
    padding: 12px 16px;
    text-align: center;
    font-size: 11px;
    color: var(--text-muted);
  }

  .footer p {
    margin: 0;
  }
</style>
