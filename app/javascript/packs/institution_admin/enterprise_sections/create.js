import EnterpriseEditSections from 'src/institution_admin/enterprise_edit_sections/enterprise_edit_sections.js';

document.addEventListener('DOMContentLoaded', () => {
  const createForm = new EnterpriseEditSections();
  createForm.initializeCreateForm();
});
