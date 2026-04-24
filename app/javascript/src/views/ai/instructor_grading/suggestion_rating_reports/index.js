import { Datepicker } from 'vanillajs-datepicker';
import { createApp } from 'vue';
import 'vanillajs-datepicker/sass/datepicker';
import AiSuggestionsFilterApp from '../../../../features/ai/instructor_grading/suggestion_rating_reports/AiSuggestionsFilterApp.vue';
document.addEventListener(
  'DOMContentLoaded',
  () => {

    const rootElm = document.querySelector('.js-ai-flagged-suggestions-filter-app');
    const aiFlaggedSugesstionsFilterDataElm = document.querySelector('.js-ai-flagged-suggestions-filter-data');
    const dataFromDom = JSON.parse(aiFlaggedSugesstionsFilterDataElm.getAttribute('data-from-dom'));

    const app = createApp(AiSuggestionsFilterApp, {
      programId: dataFromDom.program_id,
      lessons: dataFromDom.lessons,
      strandsByLesson: dataFromDom.strands_by_lesson,
      types: dataFromDom.types,
      instructors: dataFromDom.instructors,
    });

    app.mount(rootElm);
  }
);
