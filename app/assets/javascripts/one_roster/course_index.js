window.addEventListener('DOMContentLoaded', (event) => {
  let any_checkbox_checked = () => [...document.querySelectorAll('.c-form-item__checkbox')].some((element) => {
                                     return element.checked;
                                   });
  for(var checkbox of document.querySelectorAll('.c-form-item__checkbox')){
    checkbox.onclick = (event) => {
      let submit_button = document.querySelector('.js-enter');
      submit_button.disabled = !any_checkbox_checked();
    };
  }

  // Hide directions if no courses left.
  let no_courses_left_message = document.querySelector('.no-courses-left');
  if (no_courses_left_message) {
    document.querySelector('dd').style.display = 'none';
  }

  // Add confirmation modal.
  document.querySelector('.c-button.js-enter').addEventListener('click', (event) => {
    $(document.querySelector('.js-confirmation-modal')).vhlModal('open');
    event.preventDefault();
  });
});
