import StudentSettings
  from '../src/features/student_settings/StudentSettings.vue';
import { createApp } from 'vue';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    const studentSettingsElement = document.querySelector('.student-settings');
    const dataFromDom = JSON.parse(studentSettingsElement.getAttribute('data-from-dom'));

    const app = createApp(StudentSettings, dataFromDom)
    app.mount(studentSettingsElement);
  }
);
