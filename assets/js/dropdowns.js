/*
 * Dropdown Enhancements for <details> Elements
 *
 * Adds quality-of-life improvements to native <details> dropdowns:
 * - ESC key closes open dropdowns
 * - Click outside dropdown closes it
 * - Only one dropdown open at a time
 * - Dropdown closes after menu item activation
 * - Maintains graceful degradation (works without JS)
 *
 * Dropdowns using class .dropdown will automatically receive these enhancements.
 *
 * Browser Support: All modern browsers
 */

function closeDropdown(dropdown, { focusSummary = false } = {}) {
  if (!dropdown?.hasAttribute('open')) return;
  dropdown.removeAttribute('open');

  if (focusSummary) {
    const summary = dropdown.querySelector('summary');
    if (summary) {
      summary.focus();
    }
  }
}

// Ensure only one dropdown is open at a time
function setupSummaryToggleHandler() {
  document.querySelectorAll('details.dropdown').forEach(dropdown => {
    dropdown.addEventListener('toggle', () => {
      if (!dropdown.open) {
        return;
      }

      document.querySelectorAll('details.dropdown[open]').forEach(other => {
        if (other !== dropdown) {
          closeDropdown(other);
        }
      });
    });
  });
}

// Close dropdown when clicking outside
function setupClickOutsideHandler() {
  document.addEventListener('click', (e) => {
    // If clicking a summary, let the browser handle it (don't interfere)
    const clickedSummary = e.target.closest('summary');
    if (clickedSummary?.closest('details.dropdown')) {
      return;
    }

    document.querySelectorAll('details.dropdown[open]').forEach(dropdown => {
      if (!dropdown.contains(e.target)) {
        closeDropdown(dropdown);
      }
    });
  });
}

// Close dropdown when pressing ESC key
function setupEscapeKeyHandler() {
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.key === 'Esc') {
      const openDropdown = document.querySelector('details.dropdown[open]');
      if (openDropdown) {
        e.preventDefault();
        closeDropdown(openDropdown, { focusSummary: true });
      }
    }
  });
}

// Close dropdown after a menu item is activated (click, submit, etc.)
function setupMenuActivationHandler() {
  document.addEventListener('click', (e) => {
    const item = e.target.closest('.dropdown-menu a, .dropdown-menu button, .dropdown-menu [data-modal]');
    if (!item) {
      return;
    }

    const dropdown = item.closest('details.dropdown');
    if (dropdown) {
      closeDropdown(dropdown);
    }
  });
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  setupSummaryToggleHandler();
  setupClickOutsideHandler();
  setupEscapeKeyHandler();
  setupMenuActivationHandler();
});

// No exports needed - this module handles its own initialization
