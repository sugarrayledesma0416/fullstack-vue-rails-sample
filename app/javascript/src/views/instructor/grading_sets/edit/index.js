import GradingControlsApp from 'features/grading_sets/GradingControlsApp';
import { mountVueAppOnElm } from 'shared/utils/vue';
import { initCompositionEditor, initCompositionUploader } from 'mae';
import GradingSuggestionsApp from 'features/ai/instructor_grading_sets/GradingSuggestionsApp';
import GradingSuggestionsToggle from 'features/ai/instructor_grading_sets/GradingSuggestionsToggle';
import 'features/ai/instructor_grading_sets/custom_elements/index';
import { gradingSuggestionsPinia } from 'features/ai/instructor_grading_sets/stores/setup_stores';
import { createApp } from 'vue';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    initCompositionEditor('.js-grading-editor-textarea', 'grading');
    initCompositionUploader();

    const gradingControlsElm = document.querySelector('.js-grading-controls-app');
    if (gradingControlsElm) {
      mountVueAppOnElm(GradingControlsApp, '.js-grading-controls-app', true);
    }

    mountSuggestionApps();

    const aiGradingToggleElm = document.querySelector('.js-ai-grading-suggestions-toggle');
    if (aiGradingToggleElm) {
      const app = createApp(GradingSuggestionsToggle, { ...aiGradingToggleElm.dataset });
      app.use(gradingSuggestionsPinia);
      app.mount(aiGradingToggleElm);
    }
  }
);

/**
 * The mountVueAppOnElms utility creates a new Pinia for each mounted element.  While this works
 * when only one Vue app needs to access the Pinia, in this case, we need multiple Vue apps to
 * share the same Pinia.  Additionally, we need to access the store from outside of the Vue apps
 * so that it can interface with standalone JavaScript modules.
 *
 * App creation and mounting is handled here to ensure that the correct Pinia is injected into the
 * Vue apps.
 */
function mountSuggestionApps() {
  const elements = document.querySelectorAll('.js-ai-grading-suggestions-app');
  if (elements.length) {
    elements.forEach((element) => {
      const app = createApp(GradingSuggestionsApp, { ...element.dataset });
      app.use(gradingSuggestionsPinia);
      app.mount(element);
    });
  }
}

document.addEventListener(
  'initCompositionEditorEvent',
  () => {
    initCompositionEditor('.js-grading-student-original-response-textarea', 'activity');
  }
);
