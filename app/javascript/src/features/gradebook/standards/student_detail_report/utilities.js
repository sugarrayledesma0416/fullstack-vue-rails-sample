/* eslint 'camelcase': ['error', {allow: ['original_student_response']}] */
import { initCompositionEditor } from 'mae/app/javascript/src/features/composition/editor';

/**
 * Reinitialize the recording v2 items
 */
function reInitializeRecordingV2() {
  const itemContainer = document.querySelector('.js-recording-v2-item');

  if (itemContainer) {
    VHL.RecordingV2.ItemController(itemContainer);
  }
}

/**
 * Sets up composition editor
 */
function setUpCompositionEditor() {
  initCompositionEditor('.js-composition-editor-textarea', 'activity');

  const responseSelector = document.querySelector('.c-student-answer-composition');
  const openLink = document.querySelector('#original_student_response');

  if (openLink) {
    openLink.addEventListener('click', () => {
      if (responseSelector.classList.contains('hidden_helper')) {
        responseSelector.classList.remove('hidden_helper');
        original_student_response.text = 'Hide original response';
      } else {
        responseSelector.classList.add('hidden_helper');
        original_student_response.text = 'Show original response';
      }
    });
  }
}

export {
  reInitializeRecordingV2,
  setUpCompositionEditor,
};
