import FormComponent from 'institution_admin/shared/form_component.js';
import sectionDataTemplate from './section_data_template.js';
import { getFromEndpoint, postToEndpoint } from 'shared/ajax_utils.js';
import EditCourseModal from '../edit_course/edit_course_modal.js';
import CreateSectionModal from '../create_section/create_section_modal.js';
import EditSectionModal from '../edit_section/edit_section_modal.js';
import SectionCollection from '../create_section/section_collection.js';

/** @summary Form component for viewing/editing course and section data.
 */
class SectionDataComponent extends FormComponent {
  /**
   * @summary Configure and instantiate section-data component.
   */
  constructor(rootElm, context = {}) {
    const schoolId = document.querySelector('.js-school-id').dataset.schoolId;

    let config = {
      elmEventListenerMap: {
        'js-create-section': ['click', 'showCreateSectionModal'],
        'js-edit-course': ['click', 'showEditCourseModal'],
        'js-edit-section': ['click', 'showEditSectionModal'],
        'js-roster-link': ['click', 'storeSelectedCourseId']
      },
      context: {
        schoolId: schoolId
      },
      /** kludge: the markup for this component contains fully rendered markup
       *    for other components, and I don't want to create them as subcomponents
       *    of CoursesComponent. This is a case I hadn't considered.
       */
      subcomponentsToSkip: ['CourseTemplateDataComponent']
    };

    super(rootElm, config);
  }

  async init(context) {
    if (context.courseData == undefined) { return; }

    this.editCourseModalElm = this.editCourseModalElm || context.editCourseModalElm;
    this.createSectionModalElm = this.createSectionModalElm || context.createSectionModalElm;
    this.editSectionModalElm = this.editSectionModalElm || context.editSectionModalElm;

    this.sectionCollection = new SectionCollection(context.courseData.courseId, this.initialContext.schoolId);
    await this.sectionCollection.getSectionOptions();

    super.init(
      Object.assign(
        {},
        this.initialContext,
        context
      )
    );
  }

  draw(context = {}) {
    const rootElm = this.rootElm;
    const courseId = context.courseData.courseId;
    return new Promise(resolve => {
      getFromEndpoint(
        `${location.origin}/institution_admin/section_data/${courseId}?school_id=${context.schoolId}`,
        (data) => {
          // we only need a section collection if we need to be able to edit sections
          if (data.source_template_id !== null) {
            this.sectionCollection.setSections(data);
          }
          rootElm.innerHTML = sectionDataTemplate(data);
          resolve();
        }
      );
    })
  }

  showEditCourseModal(event) {
    /* The UI control is a link with an empty href; this is to prevent reloading of page. */
    event.preventDefault();
    const selectedCourseData = this.getElm('js-course-data').dataset;
    new EditCourseModal(this.editCourseModalElm, selectedCourseData).open();
  }

  async showCreateSectionModal(event) {
    /* The UI control is a link with an empty href; this is to prevent reloading of page. */
    event.preventDefault();
    const createSectionModal = new CreateSectionModal(this.createSectionModalElm);
    createSectionModal.setInitialSectionCount();
  }

  showEditSectionModal(event) {
    /* The UI control is a link with an empty href; this is to prevent reloading of page. */
    event.preventDefault();
    const sectionId = event.currentTarget.dataset.sectionId;
    let model = this.sectionCollection.mutableCopy(sectionId);

    /**
     * This element has to be cleared of content because it may contain previously rendered subcomponents,
     *   which will break the recursive building of form components.
     *
     * Consider whether it's worth finding a general solution.
     */
    document.querySelector('.js-edit-section-modal .js-form-component--section-subform-collection').innerHTML = '';

    new EditSectionModal(
      this.editSectionModalElm,
      { model: model }
    ).redrawSectionSubforms();
  }

  storeSelectedCourseId(event) {
    sessionStorage.setItem('selectedCourseId', this.selectedCourseId);
  }

  get selectedCourseId() {
    return this.getElm('js-selected-course-id').dataset.selectedCourseId;
  }

  set selectedCourseId(id) {
    this.getElm('js-selected-course-id').dataset.selectedCourseId = id;
  }

  get courseData() {
    return this.getElm('js-course-data').dataset;
  }
}

export { SectionDataComponent };
