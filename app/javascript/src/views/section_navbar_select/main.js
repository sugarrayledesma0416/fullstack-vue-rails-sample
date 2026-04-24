import { handleSectionChange } from '../../features/section_navbar_select/dropdown_utils';

document.addEventListener('DOMContentLoaded', () => {
  const selectElement = document.querySelector('.js-select-sections');

  if (selectElement) {
    selectElement.addEventListener('change', handleSectionChange);
  }
});
