window.addEventListener('DOMContentLoaded', (event) => {
  let selectElm = document.querySelector('.js-select-assign-method');
  let selectCourseElm = document.querySelector('.js-select-assign-course');

  const origin = location.origin;
  const pathname = location.pathname;

  if (selectElm) {
    /**
    * Mark the option with link pathname = current location pathname as selected.
    *
    * We compare the pathnames because the links may include query string params.
    */
     selectElm.selectedIndex = [...selectElm.options].findIndex(
      opt => new URL(`${origin}${opt.value}`).pathname == pathname
    );

    // Set up select to navigate on change.
    selectElm.addEventListener('change', (event) => {
      location = event.currentTarget.value;
    });
  }

  if (selectCourseElm) {
    selectCourseElm.addEventListener('change', (event) => {
      let selectedOption = event.currentTarget.options[event.currentTarget.selectedIndex];
      location = selectedOption.getAttribute('data-target');
    });
  }
});
