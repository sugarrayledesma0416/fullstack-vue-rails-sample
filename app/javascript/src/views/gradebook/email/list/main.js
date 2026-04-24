import { init_dispatch_click_send } from '~/src/features/email_students/main.js';

document.addEventListener('DOMContentLoaded', () => {
  /**
   * Initialize the dispatch for the email students feature,
   * setting is_institution_admin to true when the user has navigated from the
   * institution-admin roster view (in which case the URL for that view will be
   * the value of the `return_to` query parameter).
   */
  const isInstitutionAdmin = window.location.search.includes('institution_admin');
  init_dispatch_click_send(isInstitutionAdmin);
});
