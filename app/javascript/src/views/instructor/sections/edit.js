import EditSectionWizardApp from 'features/section_wizard/EditSectionWizardApp';
import { mountVueAppOnElmForSection } from 'features/section_wizard/common/section_wizard_utils';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElmForSection(EditSectionWizardApp, '.js-edit-section-wizard');
});
