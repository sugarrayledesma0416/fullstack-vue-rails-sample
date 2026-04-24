import { init_dispatch_open_feature } from '~/src/features/email_students/main.js';
import '~/src/views/roster/roster.scss';

document.addEventListener('DOMContentLoaded', () => {
  /**
   * Initialize the dispatch for the email students feature,
   * setting is_institution_admin to true.
   */
  init_dispatch_open_feature(true);
});
