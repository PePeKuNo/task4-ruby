// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"

// IMPORTANT: getUniqIdValue function (requirement: "Add getUniqIdValue function")
// NOTE: Generates a unique ID value for DOM elements
// NOTA BENE: Uses timestamp + random component for uniqueness
function getUniqIdValue(prefix = 'uid') {
  const timestamp = Date.now().toString(36);
  const randomPart = Math.random().toString(36).substring(2, 9);
  return `${prefix}_${timestamp}_${randomPart}`;
}

// NOTE: Make getUniqIdValue globally available
window.getUniqIdValue = getUniqIdValue;

// NOTE: Initialize Bootstrap tooltips globally
document.addEventListener('turbo:load', () => {
  // Initialize all tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });

  // Initialize all popovers
  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
  popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl);
  });
});

// NOTE: Auto-dismiss flash messages after 5 seconds
document.addEventListener('turbo:load', () => {
  const alerts = document.querySelectorAll('.alert:not(.alert-permanent)');
  alerts.forEach(alert => {
    setTimeout(() => {
      const bsAlert = bootstrap.Alert.getOrCreateInstance(alert);
      bsAlert.close();
    }, 5000);
  });
});

// NOTE: Confirm dialogs are handled by a Bootstrap modal inside the user-table
// Stimulus controller (see user_table_controller.js and the modal in admin/index).
// NOTA BENE: window.confirm() is a browser alert and the task forbids browser alerts,
// so the old [data-confirm] + confirm() handler was removed completely.

// NOTE: Keyboard accessibility for custom buttons
document.addEventListener('keydown', (e) => {
  // Enter/Space on buttons with data-action
  if ((e.key === 'Enter' || e.key === ' ') && e.target.matches('[data-action]')) {
    e.preventDefault();
    e.target.click();
  }
});

// Export for module usage
export { getUniqIdValue };