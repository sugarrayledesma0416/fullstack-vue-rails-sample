import { mountVueAppOnElms } from 'shared/utils/vue';
import { createApp } from 'vue';
import { createPinia } from 'pinia';
import QuestionReportApp from 'features/ai/instructor_grading/suggestion_rating_reports/QuestionReportApp';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    const elm = document.querySelector('.js-ai-instructor-grading-suggestion-rating-report-question-report-app');
    const app = createApp(QuestionReportApp, { ...elm.dataset });
    app.use(createPinia());
    app.mount(elm)
  }
);
