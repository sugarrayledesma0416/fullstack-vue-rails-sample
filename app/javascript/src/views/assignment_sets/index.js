import { createApp } from 'vue';
import { createPinia } from 'pinia';
import AssignmentSetsCalendarApp from 'features/assignment_sets_calendar/AssignmentSetsCalendarApp';

document.addEventListener('DOMContentLoaded', () => {
  const elm = document.querySelector('.js-assignment-sets-calendar');
  const app = createApp(AssignmentSetsCalendarApp, { ...elm.dataset });
  app.use(createPinia());
  app.mount(elm);
});
