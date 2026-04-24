import { mountVueAppOnElm } from 'shared/utils/vue';
import { initRecordingV2View } from 'mae';

import QuestionByQuestionV2App from
  'mae/app/javascript/src/features/question_by_question_v2/QuestionByQuestionV2App.vue';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    const questionByQuestionSelector = '.js-question-by-question-v2-app';
    const questionByQuestionElm = document.querySelector(questionByQuestionSelector);

    if (questionByQuestionElm) {
      mountVueAppOnElm(QuestionByQuestionV2App, questionByQuestionSelector);
    }
  }
);

initRecordingV2View();
