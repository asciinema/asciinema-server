/*
 * Modal Management for Native <dialog> Elements
 *
 * Features:
 * - Opens modals via data-modal="modal-id" attribute on trigger elements
 * - Closes modals via ESC key (native <dialog> behavior)
 * - Closes modals via backdrop click (click outside modal content)
 * - Closes modals via close buttons with data-modal-close attribute
 * - Restores focus to trigger element on close
 * - Double-click protection (prevents InvalidStateError)
 *
 * Usage:
 *   Trigger: <button data-modal="share-modal">Share</button>
 *   Modal: <dialog id="share-modal" class="modal">...</dialog>
 *   Close: <button class="modal-close" data-modal-close>×</button>
 *
 * Exported API:
 *   openModal(modalId, triggerElement) - Programmatically open a modal
 *   closeModal(modalId) - Programmatically close a modal
 *
 * Browser Support: Chrome 37+, Firefox 98+, Safari 15.4+, Edge 79+
 */

// Store reference to the trigger element for focus restoration
let lastTriggerElement = null;

// Open modal by ID
function openModal(modalId, triggerElement = null) {
  const modal = document.getElementById(modalId);
  if (!modal) {
    console.warn(`Modal with id "${modalId}" not found`);
    return;
  }

  // Guard: Only open if dialog exists and is not already open
  if (modal && !modal.open) {
    // Store trigger element for focus restoration when modal closes
    if (triggerElement) {
      lastTriggerElement = triggerElement;
    }

    try {
      modal.showModal();
    } catch (error) {
      // Handle rare case where showModal() fails (e.g., dialog already open)
      console.error(`Failed to open modal "${modalId}":`, error);
    }
  }
}

// Close modal by ID
function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (!modal) {
    console.warn(`Modal with id "${modalId}" not found`);
    return;
  }

  if (modal && modal.open) {
    try {
      modal.close();
    } catch (error) {
      // Handle edge case where close() fails
      console.error(`Failed to close modal "${modalId}":`, error);
    }
  }
}

// Setup modal behaviors on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  // Handle modal trigger buttons with data-modal attribute
  document.addEventListener('click', (e) => {
    const trigger = e.target.closest('[data-modal]');
    if (trigger) {
      e.preventDefault();
      const modalId = trigger.dataset.modal;
      // Pass the trigger element to openModal for focus tracking
      openModal(modalId, trigger);
    }
  });

  // Handle modal close buttons with data-modal-close attribute
  document.addEventListener('click', (e) => {
    const closeButton = e.target.closest('[data-modal-close]');
    if (closeButton) {
      e.preventDefault();
      const modal = closeButton.closest('dialog');
      if (modal) {
        modal.close();
      }
    }
  });

  // Handle backdrop clicks (clicking outside modal to close)
  document.querySelectorAll('dialog.modal').forEach(dialog => {
    dialog.addEventListener('click', (e) => {
      // Only close if clicking directly on the dialog (the backdrop area)
      // Not if clicking on dialog content
      const rect = dialog.getBoundingClientRect();
      if (
        e.clientX < rect.left ||
        e.clientX > rect.right ||
        e.clientY < rect.top ||
        e.clientY > rect.bottom
      ) {
        dialog.close();
      }
    });

    // Handle focus restoration when modal closes
    dialog.addEventListener('close', () => {
      const triggerElement = lastTriggerElement;
      // Clear the reference immediately to avoid cross-modal leakage
      lastTriggerElement = null;
      // Restore focus to the trigger element that opened the modal
      if (triggerElement && typeof triggerElement.focus === 'function') {
        // Small delay to ensure modal is fully closed before focus shift
        setTimeout(() => {
          try {
            triggerElement.focus();
          } catch (error) {
            // Element may have been removed from DOM
            console.warn('Could not restore focus to trigger element:', error);
          }
        }, 0);
      }
    });
  });

  // ESC key handling is built into <dialog> element, no JS needed
});

// Export functions for potential use elsewhere
export { openModal, closeModal };
