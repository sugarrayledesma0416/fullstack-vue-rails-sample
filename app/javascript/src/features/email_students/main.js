/**
 * Adds a 'click' event listener to dispatch a log when user performs an email-students action.
 *
 * @param {HTMLElement} element - The element to attach the event listener to.
 * @param {string} eventType - The name of the event (= the value of the log's @type field).
 * @param {boolean} is_institution_admin - Whether user is in enterprise-dashboard context.
 * @returns {void}
 */
function init_dispatch(element, eventType, is_institution_admin) {
  if(element) {
    const logstashDispatcher = new VHL.CarlinDispatch.Logstash(
      'email_students', // assigned to vhl_component in the log
      {
        is_institution_admin,
      }
    );

    element.addEventListener('click', (event) => {
      // Prevent default link behavior so that dispatch will execute
      event.preventDefault();
      event.stopPropagation();

      logstashDispatcher.dispatch(eventType);

      // Navigate to the link after dispatching
      window.location.href = event.currentTarget.href;
    });
  }
}

/**
 * @summary Sets up the `mailto:` link to dispatch a 'click_send' log when clicked.
 *
 * Note: no default value for `is_institution_admin` is provided here. The function is called from a
 * view that can be visited from both the regular-instructor and the enterprise dashboard, so the
 * value of `is_institution_admin` must be determined dynamically.
 *
 * @param {boolean} is_institution_admin - Whether user is in enterprise-dashboard context.
 * @return {void}
 */
function init_dispatch_click_send(is_institution_admin) {
  const emailStudentsLink = document.querySelector('.js-email-students-click-send');

  init_dispatch(emailStudentsLink, 'click_send', is_institution_admin);
}

/**
 * @summary Sets up the "email students" link to dispatch an 'open_feature' log when clicked.
 *
 * Note: unlike `init_dispatch_click_send`, this function is called from two separate views (one in
 * the regular-instructor dashboard context, and the other in the enterprise-dashboard context), so
 * we can set a default of `false` for `is_institution_admin` and override it in the enterprise-
 * dashboard context only.
 *
 * @param {boolean} [is_institution_admin=false] - Whether user is in enterprise-dashboard context.
 * @return {void}
 */
function init_dispatch_open_feature(is_institution_admin = false) {
  const emailStudentsLink = document.querySelector('.js-email-students-open-feature');

  init_dispatch(emailStudentsLink, 'open_feature', is_institution_admin);
}

export { init_dispatch_click_send, init_dispatch_open_feature };
