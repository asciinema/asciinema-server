/*
 * Main Application JavaScript
 *
 * Loads all interactive behavior for the application.
 * Bootstrap has been fully replaced with modern CSS and native HTML elements.
 */

// === Core Dependencies ===
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

// === Custom Interactive Behaviors ===
import './modals';      // Modal management for <dialog> elements
import './dropdowns';   // Dropdown enhancements for <details> elements
import { createPlayer, cinemaHeight } from './player';

// === Exported Functions ===
window.createPlayer = createPlayer;
window.cinemaHeight = cinemaHeight;

// === Application-Specific Behaviors ===
document.addEventListener('DOMContentLoaded', () => {
  // Mobile header nav toggle
  const navToggle = document.querySelector('.nav-toggle');
  const headerMenu = document.getElementById('header-menu');

  if (navToggle && headerMenu) {
    navToggle.addEventListener('click', () => {
      const isOpen = headerMenu.classList.contains('is-open');

      // Toggle the menu
      headerMenu.classList.toggle('is-open');

      // Update ARIA attribute for screen readers
      navToggle.setAttribute('aria-expanded', !isOpen);
    });
  }

  // Auto-focus inputs with data-behavior="focus"
  const focusInput = document.querySelector('input[data-behavior=focus]');
  if (focusInput) {
    focusInput.focus();
    focusInput.select();
  }

  // Auto-select inputs on click with data-behavior="auto-select"
  document.querySelectorAll("input[data-behavior=auto-select]").forEach(input => {
    input.addEventListener('click', () => {
      input.select();
    });
  });

  // Add noreferrer to external links when origin referrer policy is set
  if (document.querySelector('meta[name=referrer][content=origin]')) {
    document.querySelectorAll('a[href*=http]').forEach(link => {
      link.setAttribute('rel', 'noreferrer');
    });
  }

  // Download .txt link handler
  document.querySelectorAll('#download-txt').forEach(link => {
    link.addEventListener('click', () => {
      link.href = window.location.origin + window.location.pathname + '.txt';
    });
  });

  // Flash message close buttons
  document.querySelectorAll('#flash-notice button[data-behavior=close], #flash-alert button[data-behavior=close]').forEach(button => {
    button.addEventListener('click', (e) => {
      e.preventDefault();
      e.target.closest('section').classList.add('hidden');
    });
  });

  // Flash message auto-hide after 5 seconds
  setTimeout(() => {
    document.querySelectorAll('#flash-notice, #flash-alert').forEach(section => {
      section.classList.add('hidden');
    });
  }, 5000);

  // Search input keyboard shortcut (/) and validation
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

// === Phoenix LiveView Setup ===
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken } });

// Connect if there are any LiveViews on the page
liveSocket.connect();
