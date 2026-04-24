import { mountVueAppOnElm } from 'shared/utils/vue';
import Icon from 'shared/custom_elements/vhl_icon';
import JuniorDirectionLineIcon from 'views/activities/supersite_junior_activity_context/JuniorDirectionLineIcon';
customElements.define('vhl-icon', Icon);

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElm(JuniorDirectionLineIcon, '#junior_direction_line_icon');
});
