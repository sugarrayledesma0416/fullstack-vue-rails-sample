import { createApp } from 'vue';

/**
 * Mount given vue component on html element corresponding to the given selector.
 * @param {NewSectionWizardApp|EditSectionWizardApp} appClass - Vue component to host in html
 * @param {string} selector - Selector for html element which hosts vue app
 */
function mountVueAppOnElmForSection(appClass, selector) {
  const rootElm = document.querySelector(selector);
  const propsData = JSON.parse(rootElm.dataset.sectionWizardData);
  const app = createApp(appClass, propsData);
  app.mount(rootElm);
}

export { mountVueAppOnElmForSection };
