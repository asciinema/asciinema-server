let lastTriggerElement = null;

function openModal(modalId, triggerElement = null) {
  const modal = document.getElementById(modalId);
  if (!modal) {
    console.warn(`Modal with id "${modalId}" not found`);
    return;
  }

  if (modal && !modal.open) {
    // Store trigger element for focus restoration when modal closes
    if (triggerElement) {
      lastTriggerElement = triggerElement;
    }

    try {
      modal.showModal();
    } catch (error) {
      console.error(`Failed to open modal "${modalId}":`, error);
    }
  }
}

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
      console.error(`Failed to close modal "${modalId}":`, error);
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  document.addEventListener('click', (e) => {
    const trigger = e.target.closest('[data-modal]');
    if (trigger) {
      e.preventDefault();
      const modalId = trigger.dataset.modal;
      openModal(modalId, trigger);
    }
  });

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
});

export { openModal, closeModal };
