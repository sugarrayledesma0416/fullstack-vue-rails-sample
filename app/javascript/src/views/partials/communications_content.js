import { createApp } from 'vue';
import StudentNotificationListApp from 'features/notifications/StudentNotificationListApp';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    // Multiple instances of the app may be mounted in the same view.
    const appRootElms = Array.from(
      document.querySelectorAll('.js-student-notification-list')
    );
    appRootElms.forEach(
      (appRootElm) => {
        createApp(
          StudentNotificationListApp,
          { ...appRootElm.dataset }
        ).mount(appRootElm);
      }
    );
  }
);
