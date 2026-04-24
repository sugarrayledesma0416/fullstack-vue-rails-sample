import { mountVueAppOnElm } from 'shared/vue_utils';
import ShowMappedStandardsApp
  from 'features/activities/show_header_content/ShowMappedStandardsApp';

document.addEventListener('DOMContentLoaded', () => {
  const showMappedStandardsAppElm = document.querySelector('.js-show-mapped-standards');

  if (showMappedStandardsAppElm) {
    mountVueAppOnElm(ShowMappedStandardsApp, '.js-show-mapped-standards');
  }
});