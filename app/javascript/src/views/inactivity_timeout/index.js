import { createApp } from 'vue';
import InactivityTimeout from './inactivity_timeout';
import TimeoutWarningApp from './TimeoutWarningApp';

document.addEventListener('DOMContentLoaded', () => {
  mountTimeoutWarningVueApp();
});

/**
 * Mount TimeoutWarning vue app on the page.
 */
function mountTimeoutWarningVueApp() {
  const rootElm = document.querySelector('.js-vue-timeout-warning');
  if (rootElm) {
    const dataset = rootElm.dataset;
    const inactivityTimeout = new InactivityTimeout(
      {
        currentSchoolId: Number(dataset.currentSchoolId),
        enabledInSelectedSchool: Boolean(dataset.enabledInSelectedSchool),
        enabledInAnySchool: Boolean(dataset.enabledInAnySchool),
        timeoutDuration: Number(dataset.timeoutDuration),
        secondsBeforeWarning: Number(dataset.secondsBeforeWarning),
        secondsBetweenChecks: Number(dataset.secondsBetweenChecks)
      }
    );
    const app = createApp(TimeoutWarningApp, {});
    app.provide('inactivityTimeout', inactivityTimeout);
    app.mount(rootElm);
  }
}
