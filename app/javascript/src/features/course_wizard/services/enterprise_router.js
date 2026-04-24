import { createRouter, createWebHashHistory } from 'vue-router';
import LearningTracksStep from 'features/course_wizard/components/LearningTracksStep.vue';
import EnterpriseCourseStep from 'features/course_wizard/components/EnterpriseCourseStep.vue';
import EnterpriseContentStep from 'features/course_wizard/components/EnterpriseContentStep.vue';
import EnterpriseGradebookStep from 'features/course_wizard/components/EnterpriseGradebookStep.vue';
import EnterpriseSummaryStep from 'features/course_wizard/components/EnterpriseSummaryStep.vue';
import { metaTagContent } from 'shared/utils';

/**
 * @typeDef {Router}
 * @property {Function} push - navigates to a different url.
 */

const isVol = metaTagContent('VHL.vista_online_learning') === 'true';

const routes = [
  {
    path: '/learning_tracks',
    name: 'learning-tracks-step',
    component: LearningTracksStep,
  },
  {
    path: '/enterprise_course',
    name: 'enterprise-course-step',
    component: EnterpriseCourseStep,
  },
  {
    path: '/enterprise_content',
    name: 'enterprise-content-step',
    component: EnterpriseContentStep,
  },
  {
    path: '/enterprise-gradebook',
    name: 'enterprise-gradebook-step',
    component: EnterpriseGradebookStep,
  },
  {
    path: '/enterprise-summary',
    name: 'enterprise-summary-step',
    component: EnterpriseSummaryStep,
  },
];

/**
 * This method returns router instance that can be used by a Vue app.
 * @param {string} mode - add/edit
 * @return {Router}
 */
function getRouter() {
  const defaultPath = '/enterprise_course';

  routes.push({ path: '/', redirect: defaultPath });
  routes.push({ path: '/:pathMatch(.*)', name: 'bad-path', redirect: defaultPath });
  return createRouter({ history: createWebHashHistory(), routes });
}

export { getRouter };
