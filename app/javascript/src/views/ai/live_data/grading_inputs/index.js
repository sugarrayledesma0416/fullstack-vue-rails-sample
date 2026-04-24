import { mountVueAppOnElms } from 'shared/utils/vue';
import { createApp } from 'vue';
import ImporterApp from 'features/ai/live_data/grading_inputs/ImporterApp';
import ImporterDateRangeApp from 'features/ai/live_data/grading_inputs/ImporterDateRangeApp';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    mountVueAppOnElms(ImporterDateRangeApp, '.js-ai-live-data-grading-inputs-date-range-controls');
    mountVueAppOnElms(ImporterApp, '.js-ai-live-data-grading-inputs');
  }
);
