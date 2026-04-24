import { mountVueAppOnElm } from 'shared/utils/vue';
import Icon from 'shared/custom_elements/vhl_icon';
import AssessmentsApp from './AssessmentsApp';
import { VhlReturnLink } from 'shared/custom_elements/vhl_return_link';

customElements.define('vhl-icon', Icon);
customElements.define('vhl-return-link', VhlReturnLink);

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElm(AssessmentsApp, '#assessments_app');
});
