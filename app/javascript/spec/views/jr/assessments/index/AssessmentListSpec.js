import { mount } from '@vue/test-utils';
import AssessmentList from 'views/jr/assessments/index/AssessmentList';

const assessmentsData = [
  {
    'due_date': 'Wed 1/20',
    'link': 'link/to/activity/1',
    'title': 'Assessment 1',
  },
  {
    'due_date': 'Fri 1/22',
    'link': 'link/to/activity/2',
    'title': 'Assessment 2',
  },
];

function getWrapper() {
  return mount(
    AssessmentList,
    { propsData: { assessments: assessmentsData }}
  );
}

describe(
  'AssessmentList',
  () => {
    let wrapper;

    beforeEach(() => wrapper = getWrapper());

    describe(
      'content',
      () => {
        it(
          'shows due date of assessments',
          () => {
            const dueDatesText = wrapper.findAll('.test-due-date').map((elm) => elm.text());
            expect(dueDatesText).toEqual(['Due Wed 1/20', 'Due Fri 1/22']);
          }
        );

        it(
          'includes links to assessments with title as text',
          () => {
            const linkElms = wrapper.findAll('.test-assessment-link');
            const linkHrefs = linkElms.map((elm) => elm.attributes('href'));
            const linkTexts = linkElms.map((elm) => elm.text());
            expect(linkHrefs).toEqual(['link/to/activity/1', 'link/to/activity/2']);
            expect(linkTexts).toEqual(['Assessment 1', 'Assessment 2']);
          }
        );
      }
    );
  }
);
