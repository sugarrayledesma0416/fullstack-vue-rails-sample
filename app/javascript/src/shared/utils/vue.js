import { createApp } from 'vue';
import { createPinia } from 'pinia';

const mountVueAppOnElm = (appClass, selector, usePinia = false) => {
  const elm = document.querySelector(selector);
  if (elm) {
    return mountVueApp(appClass, elm, usePinia);
  } else {
    console.warn(`No element found for selector: ${selector}`);
  }
};

const mountVueAppOnElms = (appClass, selector, usePinia = false) => {
  const elms = document.querySelectorAll(selector);
  elms.forEach((elm) => {
    mountVueApp(appClass, elm, usePinia);
  });
};

const mountVueApp = (appClass, elm, usePinia = false) => {
  const app = createApp(
    appClass,
    { ...elm.dataset }
  );
  if (usePinia) {
    app.use(createPinia());
  }
  app.mount(elm);
  return app;
};

export { mountVueAppOnElm, mountVueAppOnElms };
