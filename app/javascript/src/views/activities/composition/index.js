import { initCompositionEditor, initCompositionUploader } from 'mae';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    initCompositionEditor('.js-composition-editor-textarea', 'activity');
    initCompositionUploader();
  }
);
