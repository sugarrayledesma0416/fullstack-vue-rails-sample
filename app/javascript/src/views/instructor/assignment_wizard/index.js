import { createApp } from 'vue';
import AssignmentWizardApp from 'features/assignment_wizard/AssignmentWizardApp';

document.addEventListener('DOMContentLoaded', () => {
  const rootElm = document.querySelector('.js-assignment-wizard');
  const assignmentWizardDataElm = document.querySelector('.js-assignment-wizard-data');
  const dataFromDom = JSON.parse(assignmentWizardDataElm.getAttribute('data-from-dom'));
  const app = createApp(AssignmentWizardApp, {
    loadingIconPath: dataFromDom.loading_icon_path,
  });
  app.mount(rootElm);
});
