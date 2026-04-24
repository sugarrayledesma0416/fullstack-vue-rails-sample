import '~/src/views/roster/roster.scss';
import { init_dispatch_open_feature } from '~/src/features/email_students/main.js';

document.addEventListener('DOMContentLoaded', () => {
  /**
   * Initialize the dispatch for the email students feature,
   * setting is_institution_admin to false (default value).
   */
  init_dispatch_open_feature();

  const dialog = document.querySelector('.js-section-selector-dialog');
  const rosterActions = document.querySelector('.js-roster-actions');

  handleAddStudentsEvent(dialog);
  handleCloseDialogEvent(dialog);
  // Hide the roster actions selector
  if (rosterActions) {
    rosterActions.style.display = 'none';
  }
});


const handleAddStudentsEvent = (dialog) => {
  const addStudentsButtons = document.querySelectorAll('.js-add-students');
  addStudentsButtons.forEach(button => {
    button.addEventListener('click', (event) => {
      if (dialog) {
        event.preventDefault();
        dialog.show();
      }
    });
  });
}

const handleCloseDialogEvent = (dialog) => {
  if(dialog) {
    const close = dialog.querySelector('.js-cancel-section-selector');
    close.addEventListener('click', (event) => { 
      dialog.hide();
    });
  }
}

