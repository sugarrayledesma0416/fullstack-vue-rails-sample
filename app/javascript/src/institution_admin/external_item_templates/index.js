import ExternalItemTemplatesComponent from './external_item_templates_component.js';

document.addEventListener('DOMContentLoaded', (event) => {
  const externalItemTemplatesElm = document.querySelector('.js-external-item-templates');
  const externalItemTemplatesComponent = new ExternalItemTemplatesComponent(externalItemTemplatesElm);
});
