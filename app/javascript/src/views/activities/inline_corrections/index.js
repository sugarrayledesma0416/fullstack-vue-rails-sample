import { initCompositionEditor } from 'mae';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    initCompositionEditor('.js-inline-corrections-editor-textarea', 'activity');
  }
);
