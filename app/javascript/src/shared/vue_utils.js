import { createApp } from 'vue';

// TODO: This needs a spec.
const mountVueAppOnElm = (appClass, selector) => {
  const elm = document.querySelector(selector);

  const app = createApp(
    appClass,
    { ...elm.dataset }
  );

  const vm = app.mount(elm);
};

export { mountVueAppOnElm };
