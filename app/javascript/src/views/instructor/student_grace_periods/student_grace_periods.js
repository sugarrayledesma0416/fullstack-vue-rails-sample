import '~/src/views/roster/roster.scss';

document.addEventListener('DOMContentLoaded', () => {
  const container = document.querySelector('.js-eligible-students');
  const studentCheckboxes = container.querySelectorAll('.js-checkbox');
  enableAddStudentButton(studentCheckboxes);
  bindStudentCheckboxes(container, studentCheckboxes);

  document.querySelector('.js-grace-period-form').addEventListener('submit', (event) => {
    event.preventDefault();
    const submitButton = document.querySelector('.js-grace-period-form-submit-button');
    submitButton.disabled = true;
    const loadingSpinner = document.createElement('sl-spinner');
    loadingSpinner.setAttribute('style', '--indicator-color: var(--music-red-500)');
    submitButton.appendChild(loadingSpinner);

    event.target.submit();
  });

});

/**
 * Binds change events to student checkboxes and enables the add student button.
*/
const bindStudentCheckboxes = (container, studentCheckboxes) => {
  container.addEventListener('sl-change', () => {
    enableAddStudentButton(studentCheckboxes)}
  );
}

/**
 * Enables or disables the Grade period button based on checkbox selection state.
 */
const enableAddStudentButton = (studentCheckboxes) => {
  const submitButton = document.querySelector('.js-grace-period-form-submit-button');
  submitButton.disabled = ![...studentCheckboxes].some(cb => cb.checked);
}