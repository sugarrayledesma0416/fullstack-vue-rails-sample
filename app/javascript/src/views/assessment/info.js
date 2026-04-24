import Info from 'features/assessment/Info';
import { mountVueAppOnElm } from 'shared/utils/vue';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElm(Info, '.js-assessment-info');
});
