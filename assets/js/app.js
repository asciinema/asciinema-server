import "bootstrap";
import "phoenix_html";
import { createPlayer, cinemaHeight } from './player';

window.createPlayer = createPlayer;
window.cinemaHeight = cinemaHeight;

document.addEventListener('DOMContentLoaded', () => {
  const focusInput = document.querySelector('input[data-behavior=focus]');

  if (focusInput) {
    focusInput.focus();
    focusInput.select();
  }

  document.querySelectorAll("input[data-behavior=auto-select]").forEach(input => {
    input.addEventListener('click', () => {
      input.select();
    });
  });

  if (document.querySelector('meta[name=referrer][content=origin]')) {
    document.querySelectorAll('a[href*=http]').forEach(link => {
      link.setAttribute('rel', 'noreferrer');
    });
  }

  document.querySelectorAll('#download-txt').forEach(link => {
    link.addEventListener('click', () => {
      link.href = window.location.origin + window.location.pathname + '.txt';
    })
  });

  document.querySelectorAll('#flash-notice button[data-behavior=close], #flash-alert button[data-behavior=close]').forEach(button => {
    button.addEventListener('click', (e) => {
      e.preventDefault();
      e.target.closest('section').classList.add('hidden');
    })
  });

  setTimeout(() => {
    document.querySelectorAll('#flash-notice, #flash-alert').forEach(section => {
      section.classList.add('hidden');
    });
  }, 5000);

  const searchInput = document.getElementById('search_q');

  if (searchInput) {
    const searchForm = searchInput.parentElement;

    // Setup keyboard shortcut for focusing the search input
    document.addEventListener('keydown', function(e) {
      if (e.key === '/' && !['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) {
        e.preventDefault();

        if (searchInput) {
          searchInput.focus();
          const length = searchInput.value.length;
          searchInput.setSelectionRange(length, length);
        }
      }
    });

    // Prevent search for empty input
    searchForm.addEventListener('submit', function(e) {
      if (searchInput.value.trim() === '') {
        e.preventDefault();
      }
    });
  }
});

import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken } });

// Connect if there are any LiveViews on the page
liveSocket.connect();
