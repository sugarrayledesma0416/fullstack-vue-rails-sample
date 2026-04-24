import { mountVueAppOnElms } from 'shared/utils/vue';
import { createApp } from 'vue';
import { createPinia } from 'pinia';
import RateQuestionApp from 'features/ai/live_data/grading_input_question_rating/RateQuestionApp';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    const elm = document.querySelector('.js-ai-live-data-grading-input-ratings-rate-question-app');
    const app = createApp(RateQuestionApp, { ...elm.dataset });
    app.use(createPinia());
    app.mount(elm)
  }
);
