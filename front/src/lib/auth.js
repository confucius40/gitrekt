import { writable } from 'svelte/store';
import { getToken } from './api.js';

function create() {
  const { subscribe, set, update } = writable(getToken() || null);

  return {
    subscribe,
    login: (token) => {
      localStorage.setItem('git-token', token);
      set(token);
    },
    logout: () => {
      localStorage.removeItem('git-token');
      set(null);
    },
    refresh: () => set(getToken())
  };
}

export const token = create();
