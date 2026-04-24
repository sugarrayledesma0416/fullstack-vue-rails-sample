import { createApp } from 'vue';
import ShareActivitiesApp from 'features/created_activities/ShareActivitiesApp';

document.addEventListener('DOMContentLoaded', () => {
  const activityCells = document.querySelectorAll('.js-activity-cell');
  const programID = document.querySelector('meta[name="VHL.program_id"]').getAttribute('content');
  const activityData = [];

  activityCells.forEach( (cell) => {
    const id = cell.getAttribute('data-activity-id');
    const shared = cell.getAttribute('data-is-shared') == 'true';
    const draft = cell.getAttribute('data-is-draft') == 'true';

    activityData.push({
      id: id,
      shared: shared,
      draft: draft,
    });
  });

  const rootElm = document.querySelector('.js-my-content-share-activities-app');
  const app = createApp(ShareActivitiesApp, {
    activityData: activityData,
    programID: programID,
  });
  app.mount(rootElm);
});
