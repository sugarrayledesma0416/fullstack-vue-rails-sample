import { mount } from '@vue/test-utils';
import Workset from 'views/jr/assessments/index/Workset';

const dueDate = 'Tuesday, Jan 11th 11:12 PM';
const link = 'link/to/activity';
const title = 'Lesson 1 | Lesson Test';
const worksetIconPath = '/path/to/workset.svg';

function getWrapper() {
  return mount(
    Workset,
    {
      props: {
        assessment: { 'due_date': dueDate, 'link': link, 'title': title },
        index: 1,
        worksetIconPath,
      },
    }
  );
}

describe(
  'Workset',
  () => {
    let wrapper;

    beforeEach(() => wrapper = getWrapper());

    describe(
      'content',
      () => {
        it(
          'shows due date of assessment',
          () => {
            expect(wrapper.text()).toContain(`Due ${dueDate}`);
          }
        );

        it(
          'includes link to assessment with title as text',
          () => {
            expect(
              wrapper.get('.test-assessment-link').attributes('action')
            ).toBe(link);
          }
        );
      }
    );
  }
);
