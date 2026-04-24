import { createRouter, createWebHashHistory } from 'vue-router';
import LearningTracksStep from 'features/course_wizard/components/LearningTracksStep.vue';
import ExpressCourseStep from 'features/course_wizard/components/ExpressCourseStep.vue';
import PathSelectorStep from 'features/course_wizard/components/PathSelectorStep.vue';
import AdvancedCourseStep from 'features/course_wizard/components/AdvancedCourseStep.vue';
import ContentStep from 'features/course_wizard/components/content_step/ContentStep.vue';
import GradebookStep from 'features/course_wizard/components/GradebookStep.vue';
import SummaryStep from 'features/course_wizard/components/SummaryStep.vue';
import { metaTagContent } from 'shared/utils';

/**
 * @typeDef {Router}
 * @property {Function} push - navigates to a different url.
 */

const isVol = metaTagContent('VHL.vista_online_learning') === 'true';

const routes = [
  {
    path: '/path',
    name: 'path-selector-step',
    component: PathSelectorStep,
  },
  {
    path: '/express_course',
    name: 'express-course-step',
    component: ExpressCourseStep,
  },
  {
    path: '/learning_tracks',
    name: 'learning-tracks-step',
    component: LearningTracksStep,
  },
  {
    path: '/course',
    name: 'advanced-course-step',
    component: AdvancedCourseStep,
  },
  {
    path: '/content',
    name: 'content-step',
    component: ContentStep,
  },
  {
    path: '/gradebook',
    name: 'gradebook-step',
    component: GradebookStep,
  },
  {
    path: '/summary',
    name: 'summary-step',
    component: SummaryStep,
  },
];

/**
 * This method returns router instance that can be used by a Vue app.
 * @param {string} mode - add/edit
 * @return {Router}
 */
function getRouter(mode) {
  let defaultPath;

  if (mode === 'add' && isVol) {
    defaultPath = '/path';
  } else {
    defaultPath = '/course';
  }

  routes.push({ path: '/', redirect: defaultPath });
  routes.push({ path: '/:pathMatch(.*)', name: 'bad-path', redirect: defaultPath });
  return createRouter({ history: createWebHashHistory(), routes });
}

export { getRouter };
