import { createApp } from 'vue';
import MyContentFilterApp from 'features/created_activities/MyContentFilterApp';

document.addEventListener('DOMContentLoaded', () => {
  const rootElm = document.querySelector('.js-my-content-filter-app');
  const myContentFilterDataElm = document.querySelector('.js-my-content-filter-data');
  const dataFromDom = JSON.parse(myContentFilterDataElm.getAttribute('data-from-dom'));

  const app = createApp(MyContentFilterApp, {
    programId: dataFromDom.program_id,
    twoTier: dataFromDom.two_tier,
    lessons: dataFromDom.lessons,
    units: dataFromDom.lessons_by_units,
    strandsByLesson: dataFromDom.strands_by_lesson,
    types: dataFromDom.types,
    sharedActivityCreators: dataFromDom.shared_activity_creators,
  });

  app.mount(rootElm);
});
