import SubmitConfirmation from 'features/activities/SubmitConfirmation';
import { mountVueAppOnElm } from 'shared/utils/vue';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElm(SubmitConfirmation, '.js-submit-confirmation');
});
