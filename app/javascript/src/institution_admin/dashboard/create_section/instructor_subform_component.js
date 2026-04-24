import FormComponent from 'institution_admin/shared/form_component.js';
import instructorSubformTemplate from './instructor_subform_template.js';

/**
 * @summary Component class for the instructor subform.
 */
class InstructorSubformComponent extends FormComponent {
  /**
   * @summary Configure and instantiate the component.
   * The event-listener map configures the component to update
   * its model's state on changes to the form elements.
   */
  constructor(rootElm, context) {
    const sectionSubformIndex = context.sectionSubformIndex;
    const instructorSubformIndex = rootElm.dataset.instructorSubformIndex;

    /**
     * The model for the component is the instructor in the additional-
     *   instructor collection with an index matching that of the component
     *   in the instructor-subform collection.
     */
    const additionalInstructors = context.model.additionalInstructors;
    const instructor = additionalInstructors[instructorSubformIndex];

    /**
     * componentId is a unique combination of the section and instructor index.
     *   It is used in the template to provide a unique ID for elements so that
     *   they can be associated with labels.
     */
    let componentId = `${sectionSubformIndex}-${instructorSubformIndex}`;

    let config = {
      context: Object.assign(
        {},
        { model: instructor },
        { componentId: componentId,
          instructorSubformIndex: instructorSubformIndex }
      ),
      elmEventListenerMap: {
        'fc-instructor-select': ['change', 'resetIfBlank'],
        'js-role-select': ['change', 'updateRole'],
        'js-show-instructor': ['change', 'updateShowInstructor']
      }
    };
    super(rootElm, config);
  }

  /**
   * @summary Render the component based on the context in the constructor.
   * @param {Object} context - the context defined in the constructor
   */
  draw(context) {
    /**
     * I'm setting these properties directly on the context
     *   because Handlebars by default does not allow access to
     *   the dynamic getters on the instructor model. It's a security
     *   issue, so I don't want to override it blindly.
     */
    context.instructorOptions = context.model.instructorOptions;
    context.roleOptions = context.model.roleOptions;
    context.disableRelatedInputs = context.model.disableRelatedInputs;
    this.rootElm.innerHTML = instructorSubformTemplate(context);
  }

  /**
   * @summary Reset role and show-instructor state if no instructor selected.
   * If no instructor is selected, all associated state should be reset to
   * initial values.
   * @param {Event} event - the change event for the instructor select
   */
  resetIfBlank(event) {
    /* If the instructor is now blank, reset role and show-instructor values. */
    if (event.target.value === '') {
      this.model.selectedRole = 0;
      this.model.selectedRoleName = '';
      this.model.showInstructor = false;
    }
  }

  /**
   * @summary Update model's state for selected role.
   * @param {Event} event - the change event for the role select
   */
  updateRole(event) {
    this.model.selectedRole = event.target.value;
    this.model.selectedRoleName = event.target.selectedOptions[0].text;
  }

  /**
   * @summary Update model's state for the show-instructor flag.
   * @param {Event} event - the change event for the show-instructor checkbox
   */
  updateShowInstructor(event) {
    this.model.showInstructor = event.target.checked;
  }

  /**
   * @summary Return data for the instructor.
   * @returns {Object} data for selected ID, role, and show-instructor value.
   */
  get data() {
    return this.model.data;
  }
}

export { InstructorSubformComponent };
