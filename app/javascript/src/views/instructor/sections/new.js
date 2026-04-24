import NewSectionWizardApp from 'features/section_wizard/NewSectionWizardApp';
import { mountVueAppOnElmForSection } from 'features/section_wizard/common/section_wizard_utils';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElmForSection(NewSectionWizardApp, '.js-new-section');
});
