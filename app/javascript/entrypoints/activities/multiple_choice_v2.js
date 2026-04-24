import { mountVueAppOnElm } from '~/src/shared/utils/vue';

import { initMultipleChoiceV2 } from
  'mae/app/javascript/src/features/multiple_choice_v2/index.js';
import { initInstantFeedback } from
  'mae/app/javascript/src/features/instant_feedback/index.js';
import QuestionByQuestionV2App from
  'mae/app/javascript/src/features/question_by_question_v2/QuestionByQuestionV2App.vue';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    // instantFeedback and questionByQuestion may not be enabled.
    // Don't try to mount the apps if the target divs aren't in the view.

    const instantFeedbackElm = document.querySelector('.js-instant-feedback-app');
    if (instantFeedbackElm) {
      initInstantFeedback(instantFeedbackElm.dataset);
    }

    const questionByQuestionSelector = '.js-question-by-question-v2-app';
    const questionByQuestionElm = document.querySelector(questionByQuestionSelector);

    if (questionByQuestionElm) {
      mountVueAppOnElm(QuestionByQuestionV2App, questionByQuestionSelector);
    }

    initMultipleChoiceV2(!!instantFeedbackElm, !!questionByQuestionElm);
  }
);
