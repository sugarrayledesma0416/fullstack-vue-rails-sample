import EnterpriseEditSections from 'src/institution_admin/enterprise_edit_sections/enterprise_edit_sections.js';

document.addEventListener('DOMContentLoaded', () => {
  const sectionRows = document.querySelectorAll('.js-section-row');
  const modal = new EnterpriseEditSections();
  modal.initializeButtons();

  sectionRows.forEach((section) => {
    const sectionData = JSON.parse(section.getAttribute('data-section-data'));
    const editLink = document.querySelector(`.js-edit-section-${sectionData.section}`);

    if(editLink){
      editLink.addEventListener('click', () => {
        modal.openEditModal(sectionData);
      });
    };
  });

  const elementToFade = document.querySelector('.c-flash-banner');
  const elementToFade2 = document.querySelector('.c-flash-banner-group');

  if(elementToFade){
    setTimeout(() => {
      elementToFade.classList.add('banner-fade-out');
      elementToFade2.classList.add('banner-fade-out');
    }, 3000);
  }
});
