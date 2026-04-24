import { mount } from '@vue/test-utils';
import AssessmentsApp from 'views/jr/assessments/index/AssessmentsApp';

describe(
  'AssessmentsApp',
  () => {
    let wrapper;
    let data;
    const worksetIconPath = '/path/to/workset.svg';
    const finishedIconPath = '/path/to/finished.svg';

    function getWrapper() {
      return mount(
        AssessmentsApp,
        {
          props: {
            assessmentsData: JSON.stringify(data),
            finishedIconPath,
            worksetIconPath
          }
        }
      );
    }

    beforeEach(
      () => {
        data = {
          'to-do': [
            {
              'due_date': 'Monday, Jan 18th',
              'link': 'link/to/activity',
              'title': 'Lesson 3 | Lesson Test',
            },
            {
              'due_date': 'Tuesday, Jan 19th',
              'link': 'link/to/activity',
              'title': 'Lesson 4 | Lesson Test',
            },
            {
              'due_date': 'Wednesday, Jan 20th',
              'link': 'link/to/activity',
              'title': 'Lesson 5 | Lesson Test',
            },
          ],
          'finished': [
            { 'due_date': 'Mon Jan 11', 'title': 'Lesson 1 | Lesson Test' },
            { 'due_date': 'Wed Jan 13', 'title': 'Lesson 2 | Lesson Test' },
          ],
        };
      }
    );

    function finishedBlock() {
      return wrapper.find('.test-assessment-finished-list');
    }

    function toDoBlock() {
      return wrapper.find('.test-assessment-to-do-list');
    }

    function expectFinishedBlock() {
      expect(finishedBlock().exists()).toBeTruthy();
    }

    function expectNoFinishedBlock() {
      expect(finishedBlock().exists()).toBeFalsy();
    }

    function expectToDoBlock() {
      expect(toDoBlock().exists()).toBeTruthy();
    }

    function expectNoEmptyAssessmentsMessage() {
      expect(wrapper.text()).not.toContain('You have no assessments');
    }

    function expectNoAllAssessmentsFinishedMessage() {
      expect(wrapper.text()).not.toContain(
        'You finished all your assessments'
      );
    }

    describe(
      'when there are both to-do and finished assessments',
      () => {
        beforeEach(() => wrapper = getWrapper());

        it('displays a To Do block', expectToDoBlock);

        it('displays a Finished block', expectFinishedBlock);

        it(
          'does not show a message that there are no assessments',
          expectNoEmptyAssessmentsMessage
        );
      }
    );

    describe(
      'when there are neither to-do or finished assessments',
      () => {
        beforeEach(
          async () => {
            data['to-do'] = [];
            data['finished'] = [];
            wrapper = getWrapper();
          }
        );

        it(
          'does not display a To Do block',
          () => expect(toDoBlock().exists()).toBeFalsy()
        );

        it(
          'does not display a message that all assessments are finished',
          expectNoAllAssessmentsFinishedMessage
        );

        it('does not display a Finished block', expectNoFinishedBlock);

        it(
          'shows a message that there are no assessments',
          () => {
            expect(wrapper.text()).toContain('You have no assessments');
          }
        );
      }
    );

    describe(
      'when there are to-do assessments but no finished assessments',
      () => {
        beforeEach(
          async () => {
            data['finished'] = [];
            wrapper = getWrapper();
          }
        );

        it('displays a To Do block', expectToDoBlock);

        it(
          'does not display a message that all assessments are finished',
          expectNoAllAssessmentsFinishedMessage
        );

        it('does not display a Finished block', expectNoFinishedBlock);

        it(
          'does not show a message that there are no assessments',
          expectNoEmptyAssessmentsMessage
        );
      }
    );

    describe(
      'when there are finished assessments but no to-do assessments',
      () => {
        beforeEach(
          async () => {
            data['to-do'] = [];
            wrapper = getWrapper();
          }
        );

        it('displays a To Do block', expectToDoBlock);

        it(
          'displays a message that all assessments are finished',
          () => {
            expect(wrapper.text()).toContain(
              'You finished all your assessments'
            );
          }
        );

        it('displays a Finished block', expectFinishedBlock);

        it(
          'does not show a message that there are no assessments',
          expectNoEmptyAssessmentsMessage
        );
      }
    );
  }
);
