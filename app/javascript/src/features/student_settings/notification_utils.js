/**
 * Creates and displays a toast notification
 * @param {string} message - The message to display
 * @param {string} variant - The variant of the alert (primary, success, danger, etc.)
 * @param {string} icon - The icon to display
 * @param {number} duration - How long the toast should be displayed in milliseconds
 * @param {string} testId - The data-testid attribute value
 * @returns {Promise} - The toast promise
 */
export function notify(message, variant = 'primary', icon = 'info-circle', duration = 3000, testId = 'notification-alert') {
  const alert = Object.assign(document.createElement('sl-alert'), {
    variant,
    closable: true,
    duration,
    innerHTML: `
      <sl-icon name="${icon}" slot="icon" library="untitled-ui"></sl-icon>
      <div>${message}</div>
    `
  });
  alert.setAttribute('data-testid', testId);

  document.body.append(alert);
  const toastPromise = alert.toast();

  // Add ns-music-v3 class to the toast stack
  const toastStack = document.querySelector('.sl-toast-stack');
  if (toastStack) {
    toastStack.classList.add('ns-music-v3');
  }

  return toastPromise;
}
