import EnterpriseEditSections from 'src/institution_admin/enterprise_edit_sections/enterprise_edit_sections.js';

document.addEventListener('DOMContentLoaded', () => {
  const sectionDataElm = document.querySelector('.js-section-data');
  const sectionData = JSON.parse(sectionDataElm.getAttribute('data-section-data'));
  const editForm = new EnterpriseEditSections();
  editForm.initializeEditForm();
  editForm.buildEditForm(sectionData);
});
