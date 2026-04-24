import FormComponent from 'institution_admin/shared/form_component.js';
import sectionSubformCollectionTemplate from './section_subform_collection_template.js';

class SectionSubformCollectionComponent extends FormComponent {
  constructor(rootElm, context = {}) {
    let config = {
      context: context
    };

    super(rootElm, config);
  }

  draw(context) {
    if (Object.entries(context).length === 0) { return; }

    this.rootElm.innerHTML = sectionSubformCollectionTemplate(context);
  }
}

export { SectionSubformCollectionComponent };
