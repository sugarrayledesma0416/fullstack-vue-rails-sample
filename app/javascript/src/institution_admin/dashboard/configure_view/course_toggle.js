import { getSearchParam, programId } from 'shared/utils.js';
import { postToEndpoint } from 'shared/ajax_utils.js';

/**
 * Returns array of values for the checked checkbox inputs.
 * @return {array} Array of strings representing course IDs.
 */
const getUncheckedCourseIds = () => {
  return [
    ...document.querySelectorAll('.js-toggle-show')
  ]
  .filter(elm => !elm.checked)
  .map(elm => elm.value);
};

/**
 * Posts request to toggle-courses endpoint.
 * @param {array} ids An array of strings representing course IDs.
 */
const postToggleCoursesRequest = (ids) => {
  let schoolId = getSearchParam(location.search, 'school_id');
  let url = `${location.origin}/institution_admin/configure_view/${programId()}/toggle_admin_show?school_id=${schoolId}`;
  postToEndpoint(
    url,
    { course_ids: ids },
    (response) => {
      location.reload();
    }
  );
};

window.onbeforeunload = function () {
  window.scrollTo(0, 0);
};

export { getUncheckedCourseIds, postToggleCoursesRequest };
