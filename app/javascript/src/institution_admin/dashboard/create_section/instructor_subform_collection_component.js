import FormComponent from 'institution_admin/shared/form_component.js';
import instructorSubformCollectionTemplate from './instructor_subform_collection_template.js';

/**
 * @summary Component class for a section's collection of instructor subforms.
 * Maintains state of additional instructors for section.
 */
class InstructorSubformCollectionComponent extends FormComponent {
  /**
   * @summary Configure and instantiate component.
   * The event-listener map configures the component to
   * 1. update state for the additional instructors, on changes to any instructor
   * 2. add an instructor subform, on clicking "add more"
   * @param {HTMLElement} rootElm - the root element of the component
   * @param {Object} context - data to instantiate and render the component
   */
  constructor(rootElm, context) {
    /**
     * Get the section that corresponds to the parent component.
     * Its additional-instructor collection will be the model for
     * this component.
     */
    const sectionSubformIndex = context.sectionSubformIndex;
    const additionalInstructorCollection = context.sections[sectionSubformIndex].additionalInstructorCollection;

    let config = {
      elmEventListenerMap: {
        'fc-instructor-subform-container': ['change', 'updateInstructorSubforms'],
        'fc-add-more': ['click', 'appendSubform']
      },
      context: {
        model: additionalInstructorCollection,
        sectionSubformIndex: sectionSubformIndex
      }
    };
    super(rootElm, config);
  }

  /**
   * @summary Render the component.
   * @param {Object} context - the context defined in the constructor
   */
  draw(context) {
    this.rootElm.innerHTML = instructorSubformCollectionTemplate(context);
  }

  /**
   * @summary Redraw the component.
   */
  redraw() {
    /* Redraw the component. */
    const context = Object.assign(
      {},
      this.initialContext,
      { disableAddMore: !(this.model.canAddInstructors) }
    );

    this.init(context);
  }

  /**
   * @summary Update the model, then redraw the component.
   * @param {Event} event - a change event from one of the instructor subforms
   */
  updateInstructorSubforms(event) {
    /* Get the selected instructor (if any) and update the model. */
    const target = event.target;
    const instructorIndex = target.dataset.instructorSubformIndex;
    const selectedInstructorID = target.value;
    this.model.updateSelectedInstructors(instructorIndex, selectedInstructorID);

    this.redraw();
  }


  /**
   * @summary Add an instructor to collection, then redraw the component.
   * @param {Event} event - a click event on the "Add more" button
   */
  appendSubform(event) {
    /* Add the instructor. */
    this.model.addInstructor();

    /* The new instructor needs to have its selectedInstructors set. */
    this.model.updateSelectedInstructors();

    this.redraw();
  }
}

export { InstructorSubformCollectionComponent };
