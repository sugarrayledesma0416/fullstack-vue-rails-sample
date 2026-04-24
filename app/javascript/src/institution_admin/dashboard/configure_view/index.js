import { getUncheckedCourseIds, postToggleCoursesRequest } from './course_toggle.js';;

/**
 * Checks whether stringified versions of arrays are equal.
 *
 * This could be useful elsewhere, but I'm not ready to promote it to
 * shared/utils.js yet.
 */
function arraysMatch(arr1, arr2) {
  return JSON.stringify(arr1) === JSON.stringify(arr2);
}

/**
 * On DOMContentLoaded, set up "Save Changes" button to post to endpoint.
 * The data to be posted should be a list of IDs for the courses that are
 * _not_ checked (i.e., the courses that should be hidden).
 */
window.addEventListener('DOMContentLoaded', (event) => {
  /**
   * Assign the submit button as we'll use it in a few places.
   */
  let submitButton = document.querySelector('.js-toggle-courses');

  /**
   * Get initial list of unchecked course IDs.
   */
  let initialUncheckedCourseIds = getUncheckedCourseIds();

  /**
   * On any toggle of course show, compare initial list with current list.
   * If same, disable Submit button.
   * If different, enable.
   */
  document.querySelectorAll('.js-toggle-show-radio').forEach(elm => {
    elm.addEventListener(
      'click',
      (e) => {
        e.preventDefault();
        e.stopPropagation();
        const previousElement = elm.previousElementSibling;
        if(previousElement.checked == true){
          previousElement.checked = false;
        } else {
          previousElement.checked = true;
        }
        if (arraysMatch(getUncheckedCourseIds(), initialUncheckedCourseIds)) {
          submitButton.setAttribute('disabled', '');
        } else {
          submitButton.removeAttribute('disabled');
        }
      }
    );
  });

  submitButton.addEventListener(
    'click',
    () => {
      if (window.submitted) { return; }
      postToggleCoursesRequest(getUncheckedCourseIds());
      window.submitted = true;
    }
  )
});
