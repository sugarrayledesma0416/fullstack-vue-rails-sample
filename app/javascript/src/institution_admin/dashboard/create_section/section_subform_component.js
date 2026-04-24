import FormComponent from 'institution_admin/shared/form_component.js';
import sectionSubformTemplate from './section_subform_template.js';

/**
 * @summary Component class for an individual section in the create-section modal.
 */
class SectionSubformComponent extends FormComponent {
  /**
   * @summary Configure and instantiate the component.
   * The event-listener map configures the component to update the state of the
   * component on changes to the section name, source section template, and
   * show-owner flag.
   *
   * The context sets the model for the component based on the component's
   * index in the section-subform collection. The section-subform collection
   * has a section collection as its model. The component stores its index
   * in the DOM, and its model is the section at that same index in the
   * section collection.
   * @param {HTMLElement} rootElm - the root element of the component
   * @param {Object} context - a context object passed from the parent component
   */
  constructor(rootElm, context) {
    const sectionSubformIndex = rootElm.dataset.sectionSubformIndex;
    let config = {
      elmEventListenerMap: {
        'js-section-name': ['change', 'updateSectionName'],
        'js-section-template': ['change', 'updateSectionTemplate'],
        'js-show-owner': ['change', 'updateShowOwner']
      },
      context: Object.assign(
        {},
        context,
        { sectionSubformIndex: sectionSubformIndex,
          model: context.sections[sectionSubformIndex] }
      )
    };
    super(rootElm, config);
  }

  /**
   * @summary Render the view for the section subform.
   * @param {Object} context - the context assigned in the constructor
   */
  draw(context) {
    this.rootElm.innerHTML = sectionSubformTemplate(context);
  }

  /**
   * @summary Update the section name in the model.
   * This is passed as a change event handler for the section-name input.
   * @param {Event} event - the change event
   */
  updateSectionName(event) {
    this.model.sectionName = event.target.value;
  }

  /**
   * @summary Update the section template in the model.
   * This is passed as a change event handler for the section-template select.
   * @param {Event} event - the change event
   */
  updateSectionTemplate(event) {
    this.model.selectedTemplate = event.target.value;
  }

  /**
   * @summary Update the show-owner flag in the model.
   * This is passed as a change event handler for the show-owner checkbox.
   * @param {Event} event - the change event
   */
  updateShowOwner(event) {
    this.model.showOwner = event.target.checked;
  }
}

export { SectionSubformComponent };
