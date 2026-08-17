<script>
  import { token } from '$lib/auth.js';
</script>

<div class="hero">
  <div class="content">
    <h1>GitRekt</h1>
    <p class="tagline">minimal git forge</p>
    <p class="desc">I mean just sexy asf</p>

    <div class="ctas">
      <a href="/explore" class="btn-primary">explore repos</a>
      {#if $token}
        <a href="/admin/tokens" class="btn-secondary">manage tokens</a>
      {:else}
        <p class="note">login to create and manage tokens</p>
      {/if}
    </div>
  </div>
</div>

<style>
  .hero {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: calc(100vh - 120px);
    padding: 32px 16px;
  }

  .content {
    text-align: center;
    max-width: 600px;
  }

  h1 {
    font-size: 48px;
    font-weight: 600;
    margin: 0 0 8px;
    letter-spacing: 2px;
  }

  .tagline {
    font-size: 18px;
    color: var(--text-secondary);
    margin: 0 0 16px;
    font-weight: 400;
  }

  .desc {
    font-size: 13px;
    color: var(--text-muted);
    line-height: 1.8;
    margin: 0 0 32px;
    max-width: 500px;
    margin-left: auto;
    margin-right: auto;
  }

  .ctas {
    display: flex;
    gap: 16px;
    justify-content: center;
    flex-wrap: wrap;
  }

  .btn-primary, .btn-secondary {
    display: inline-block;
    padding: 10px 20px;
    font-size: 13px;
    border-radius: 4px;
    text-decoration: none;
    font-weight: 500;
    transition: opacity 0.15s;
  }

  .btn-primary {
    background: var(--text-accent);
    color: #fff;
    border: 1px solid var(--text-accent);
  }

  .btn-primary:hover {
    opacity: 0.9;
  }

  .btn-secondary {
    background: transparent;
    color: var(--text-accent);
    border: 1px solid var(--text-accent);
  }

  .btn-secondary:hover {
    background: var(--surface-1);
  }

  .note {
    font-size: 12px;
    color: var(--text-muted);
    margin: 0;
    font-style: italic;
  }
</style>
