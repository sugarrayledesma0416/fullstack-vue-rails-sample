import { createApp, useAttrs } from 'vue';
import { createPinia } from 'pinia';
import TourGuideInitializerApp from 'features/tour_guide/TourGuideInitializerApp';

document.addEventListener('DOMContentLoaded', () => {
  const elm = document.querySelector('.js-tour-guide-initializer');
  const app = createApp(TourGuideInitializerApp, { ...elm.dataset });
  app.use(createPinia());
  app.mount(elm);
});
