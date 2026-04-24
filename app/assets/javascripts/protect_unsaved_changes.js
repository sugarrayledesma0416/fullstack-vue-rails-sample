var VHL = VHL || {}

VHL.SaveProtection = (function() {
  function init() {
    $('form.main').each(function() {
      $(this).data('initialForm', $(this).serialize());
    }).submit(function() {
      window.removeEventListener('beforeunload', beforeUnloadHandler);
    });

    $('form.main').on('change', 'input, textarea, select', function() {
      assignUnsavedChangesHandler();
    });
  }

  function beforeUnloadHandler(event) {
    event.preventDefault();
    event.returnValue = true;
  }

  function assignUnsavedChangesHandler() {
    var changed = false;
    $('form.main').each(function() {
      if ($(this).data('initialForm') !== $(this).serialize()) {
        changed = true;
      } else if ($('div#flash_error').length > 0 || $('div.c-message--error li').length > 0) {
        changed = true;
      }
    });

    if (changed && !VHL.Common.shouldPreventWarningsAfterTimeout()) {
      window.addEventListener('beforeunload', beforeUnloadHandler);
    } else {
      window.removeEventListener('beforeunload', beforeUnloadHandler);
    }
  }

  return {
    init: init
  }
})();

$(document).ready(function() {
  VHL.SaveProtection.init();
});
