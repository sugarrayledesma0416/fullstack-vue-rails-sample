import FormComponent from 'institution_admin/shared/form_component.js';
import { getFromEndpoint } from '../../../shared/ajax_utils.js';
import EditCourseModal from '../edit_course/edit_course_modal.js';

/** @summary Parent form component for the courses view.
 */
class CoursesComponent extends FormComponent {

  /**
   * @summary Configure and instantiate courses component.
   * The event listener map configures the component to handle a click on an
   * element in the course list by getting section data for the course and
   * updating the view with it.
   */
  constructor(rootElm) {
    /**
     * Get selected course ID, if any, then clear the key immediately to avoid
     * unexpected state-related bugs.
     *
     * Any code that either navigates away from or reloads the courses view,
     * and that intends the current course to stay selected on reload,
     * can set this key.
     */
    const selectedCourseId = sessionStorage.getItem('selectedCourseId');
    sessionStorage.removeItem('selectedCourseId');

    let config = {
      elmEventListenerMap: {
        'js-course-link': ['click', 'getAndPopulateSectionData']
      },
      context: {
        selectedCourseId: selectedCourseId
      },
      /** kludge: the markup for this component contains fully rendered markup
       *    for other components, and I don't want to create them as subcomponents
       *    of CoursesComponent. This is a case I hadn't considered.
       */
      subcomponentsToSkip: ['CourseTemplateDataComponent', 'SectionSubformCollectionComponent', 'SectionSubformComponent']
    };

    super(rootElm, config);
  }

  /**
   * @summary Run initial actions after component is created.
   * Immediately after instantiation, click on the currently selected
   * course to populate section data. If no course is currently selected,
   * click on the first course in the list.
   */
  async init() {
    await super.init();

    let selectedCourseLinkElm;
    let selectedCourseId = this.initialContext.selectedCourseId;

    if (selectedCourseId) {
      selectedCourseLinkElm = this.getElm(`js-course-link-${selectedCourseId}`);
    } else {
      selectedCourseLinkElm = this.getElm('js-course-link');
    }

    const courseData = selectedCourseLinkElm.querySelector('.js-course-data').dataset;
    this.renderSectionData(courseData);
  }

  /**
   * Send and handle AJAX request for a course's section data.
   * This method is passed as a handler for the click event on course-link
   * elements.
   * @param {Event} event - click event from one of the divs in the course list.
   */
  getAndPopulateSectionData(event) {
    event.preventDefault();
    const courseData = event.currentTarget.querySelector('.js-course-data').dataset;
    this.renderSectionData(courseData);
  }

  /**
   * Renders section information for the course.
   * @param {Object} courseData The course data with which to initialize the
   * section data components.
   */
  renderSectionData(courseData) {
    window.scrollTo(0, 0);
    this.sectionDataComponents[0].init({
      courseData,
      editCourseModalElm: this.getElm('js-edit-course-modal'),
      createSectionModalElm: this.getElm('js-create-section-modal'),
      editSectionModalElm: this.getElm('js-edit-section-modal'),
    });
  }
}

export { CoursesComponent };
