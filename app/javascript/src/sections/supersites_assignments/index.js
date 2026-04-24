import { mountVueAppOnElm } from 'shared/utils/vue';
import AssignmentsApp from 'sections/supersites_assignments/AssignmentsApp';

document.addEventListener('DOMContentLoaded', () => {
  const app = mountVueAppOnElm(AssignmentsApp, '#assignments_app');
  app.config.globalProperties.window = window;
});
