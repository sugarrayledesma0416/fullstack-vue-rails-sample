import CourseOrSectionModal from '../shared/course_or_section_modal.js';
import SectionCollection from './section_collection.js';

/**
 * @summary Component class for the create-section modal.
 */
class CreateSectionModal extends CourseOrSectionModal {
  /**
   * @summary Configure and instantiate create-course-modal component.
   * The event listener map configures the component to
   * 1. update the modal, on changing the section count
   * 2. post data for the section to be created, on clicking "create"
   * 3. enable or disable the create button, on changes to the section subforms
   */
  constructor(rootElm) {
    let config = {
      elmEventListenerMap: Object.assign(
        {},
        CourseOrSectionModal.elmEventListenerMap['section'],
        {
          'fc-section-count': ['change', 'updateSectionSubforms']
        }
      ),
      context: { endpoint: `${location.origin}/institution_admin/create_section` }
    };

    /**
     * If the modal has been opened before, there will already be markup for
     * section-subform components in the section-subform-collection element.
     * Remove the markup to avoid any bugs that would result from
     * `FormComponent#buildFormComponentCollection` automatically detecting and
     * attempting to build those components.
     */
    rootElm.querySelector('.js-form-component--section-subform-collection').innerHTML = '';

    super(rootElm, config);
  }

  /**
   * @summary Force initial drawing of one section subform.
   * The modal will open after the section-subform-collection
   * element is initialized.
   */
  open() {
    this.getElm('fc-section-count').selectedIndex = 0;
    this.getElm('fc-section-count').dispatchEvent(new Event('change'));
  }

  /**
   * @summary Redraw the section subforms.
   */
  redrawSectionSubforms(data) {
    const context = {
      sections: this.model.sections,
      sectionOptions: this.model.sectionOptions
    };

    /** Subcomponents are stored in arrays named for the subcomponent
     *    class. Here, there's always only one section subform collection,
     *    so we need only the first item.
     */
    this.sectionSubformCollectionComponents[0].init(context);

    /** Open modal after subforms are initialized, to reduce chance of user seeing
     *    an initially empty set of subforms.
     *
     *  Has no effect if modal element is already visible.
     */
    $(this.rootElm).vhlModal('open');
  }

  /**
   * @summary On section-count change, update model and redraw section subforms.
   * Update model with new count and redraw. Also toggle enabled state of
   * "create" button in case new, incompletely configured sections have been
   * added.
   */
  updateSectionSubforms(event) {
    this.sectionCount = parseInt(event.target.value, 10);
    this.model.updateSectionCount(this.sectionCount);
    /* Because this method is passed unbound to the event-handler code
     * in the base class, any internal methods that it calls have to be
     * bound to `this`.
     */
    this.redrawSectionSubforms.bind(this)();

    /* Validate state of form in case sections have been added. Any additional
     *   section initially won't have enough data to submit.
     */
    this.toggleSubmitButton.bind(this)();
  }

  /**
   * @summary Set initial state of component, with one section in collection.
   * Called in ./index.js on clicking "Create section".
   */
  async setInitialSectionCount() {
    /* Wait until all event listeners are added so that section-count change will work. */
    await this.confirmInitialization();

    /** Assign new model instance. Subsequent changes of section count
     *    will use this instance. If the modal is closed, re-opening
     *    it will then assign another model instance.
     */
    const courseId = document.querySelector('.js-selected-course-id').dataset.selectedCourseId;
    const schoolId = document.querySelector('.js-school-id').dataset.schoolId;
    this.model = new SectionCollection(courseId, schoolId);

    /** Model requests section options (i.e. data for prospective additional
     *    instructors).
     *
     *  Once it has data, force initial drawing of one section subform.
     *    The modal will open after the section-subform-collection
     *    element is initialized.
     */
    await this.model.getSectionOptions();

    const sectionCountElm = this.getElm('fc-section-count');
    sectionCountElm.selectedIndex = 0;
    sectionCountElm.dispatchEvent(new Event('change'));
  }

  /**
   * @summary Return data for sections to be created.
   */
  get data() {
    return {
      course_id: this.model.courseId,
      sections: this.model.data
    };
  }
}

export default CreateSectionModal;
