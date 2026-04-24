import { createApp } from 'vue';
import VocabToolWords from 'features/vocab_tools/words/VocabToolWords';
import Icon from 'shared/custom_elements/vhl_icon';
customElements.define('vhl-icon', Icon);

document.addEventListener('DOMContentLoaded', async () => {
  const rootElm = document.querySelector('.js-vocabulary-tools');
  const dataFromDom = JSON.parse(rootElm.getAttribute('data-from-dom'));
  const app = createApp(VocabToolWords);
  if (dataFromDom) {
    app.provide('flipIconPath', dataFromDom.flip_icon_path);
    app.provide('magnifyingGlassIconPath', dataFromDom.magnifying_glass_icon_path);
    app.provide('startIconPath', dataFromDom.flashcard_start_icon_path);
  }
  app.mount(rootElm);
});
