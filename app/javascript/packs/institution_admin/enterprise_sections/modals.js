document.addEventListener('DOMContentLoaded', () => {
  // Move modals to body to avoid style conflicts with c-scrollbar-v3--fade-effect
  document.querySelectorAll('.c-modal').forEach(modal => {
    document.body.appendChild(modal);
  });
});
