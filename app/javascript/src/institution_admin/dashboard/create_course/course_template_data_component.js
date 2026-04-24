import FormComponent from 'institution_admin/shared/form_component.js';
import courseTemplateDataTemplate from './course_template_data_template.js';
import { getFromEndpoint } from '../../../shared/ajax_utils.js';

/**
 * @summary Component class for course-template data.
 * Renders course template data received from endpoint.
 */
class CourseTemplateDataComponent
  extends FormComponent {
  /**
   * @summary Render the component.
   * If a course template ID is provided in the context, get data for the
   *   course template from the endpoint and render the component.
   *
   * There are two cases in which the method returns without requesting
   *   the endpoint data:
   *
   * 1. Context is an empty object: method is a no-op
   * 2. Course template ID is blank (''): method removes all content from the
   *    component
   * @param {Object} context - data for rendering the template
   */
  async draw(context = {}) {
    /* If empty context passed in, do nothing */
    if (Object.keys(context).length === 0) { return; }

    let courseTemplateId = context.courseTemplateId;

    /* If course template ID is blank, erase the component content */
    if (courseTemplateId === '') {
      // clear the course template data
      this.rootElm.innerHTML = '';
      return;
    }

    const programId = this.rootElm.dataset.programId;
    const schoolId = this.rootElm.dataset.schoolId;

    /* Course template ID is non-blank: get data and render component.
     * Don't resolve the promise until the innerHTML is set.
     * The edit-course modal will wait until the promise resolves
     * so that the innerHTML here won't be changed after the modal opens. */
    return new Promise(resolve => {
      getFromEndpoint(
        `${location.origin}/institution_admin/${programId}/school/${schoolId}/course_template_data/${courseTemplateId}`,
        (data) => {
          this.rootElm.innerHTML = courseTemplateDataTemplate(data);
          resolve();
        }
      );
    });
  }

  /**
   * @summary Erase the component's content.
   */
  erase() {
    this.rootElm.innerHTML = '';
  }
}

export { CourseTemplateDataComponent };
