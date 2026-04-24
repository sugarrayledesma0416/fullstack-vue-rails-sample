import { createApp } from 'vue';
import { createPinia } from 'pinia';
import 'music/app/javascript/src/v3/styles/index.scss';
import StandardsAssigningApp from 'features/standards_assigning/StandardsAssigningApp';

document.addEventListener('DOMContentLoaded', () => {
  const elm = document.querySelector('.js-standards-assigning');

  if (VHL && VHL.focus) {
    VHL.focus.fromStandardsSearch = true;
  }

  const props = {
    ...elm.dataset,
    contentLibrary: VHL.ContentLibrary,
    vhlCommon: VHL.Common,
    vhlAssessments: VHL.Assessments,
  };
  const app = createApp(StandardsAssigningApp, props);
  app.use(createPinia());
  app.mount(elm);
});
