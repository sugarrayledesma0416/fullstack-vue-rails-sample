import { mountVueAppOnElm } from 'shared/utils/vue';
import IndividualAssignmentsApp
  from 'features/individual_assignments/IndividualAssignmentsApp';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    mountVueAppOnElm(
      IndividualAssignmentsApp,
      '.js-individual-assignments-app',
      true
    );
    // Fade flash banner out after 10 seconds because it obscures the save button.
    const banner = document.getElementsByClassName('js-flash-banner-group')[0];
    banner.classList.add('can-fade');
    setTimeout(
      () => {
        banner.classList.add('is-faded-out');
        banner.innerHTML = '';
      }, 10000
    );
  }
);
