import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import AssignmentSetList from 'features/assignment_sets_calendar/AssignmentSetList';

const assignmentSets = [
  {
    due_date: '01-07-2022',
    dueDateAsDate: new Date('01-07-2022'),
    hasCustomOrder: false,
  },
  {
    due_date: '01-20-2022',
    dueDateAsDate: new Date('01-20-2022'),
    hasCustomOrder: true,
  },
]

const courseStartDate = '01/01/2022';
const courseEndDate = '01/31/2022';

describe(
  'AssignmentSetList',
  () => {
    let wrapper;
    function getWrapper() {
      return mount(
        AssignmentSetList,
        {
          global: {
            plugins: [
              createTestingPinia(
                {
                  stubActions: false,
                  initialState: {
                    store: {
                      assignmentSets: assignmentSets,
                      calendar: {
                        dateRange: {
                          start: null,
                          end: null,
                        },
                        attributes: [],
                        courseStartDate: courseStartDate,
                        courseEndDate: courseEndDate,
                      },
                      dragState: {
                        hoverPosition: '',
                        originalSetDueDate: null,
                        setDueDate: null,
                        entryIndex: null,
                      },
                      errors: [],
                      showCustomOrderConfirmation: false,
                      showDefaultOrderConfirmation: false,
                      skipConfirmations: false,
                      unconfirmedChange: null,
                    },
                  },
                }
              ),
            ],
          },
        }
      );
    }

    beforeEach(
      () => {
        wrapper = getWrapper();
      }
    );

    describe('when there are no assignments', () => {
      beforeEach(
        () => {
          wrapper.vm.store.assignmentSets = [];
        }
      );
        it('shows the message - there are no assignments', () => {
          expect(wrapper.find('.test-no-assignments-message').isVisible()).toBeTruthy();
        });
      });

    describe('when there are no assignments in the selected date range', () => {
      beforeEach(
        () => {
          wrapper.vm.store.calendar.dateRange.start = new Date('01/01/2022');
          wrapper.vm.store.calendar.dateRange.end = new Date('01/05/2022');
        }
      );
        it('shows the message - there are no assignments', () => {
          expect(wrapper.find('.test-no-assignments-message').isVisible()).toBeTruthy();
        });
    });

    describe('when there are no custom ordered assignments and the custom ordered checkbox is selected',
      () => {
        beforeEach(
          () => {
            wrapper.vm.store.calendar.dateRange.start = new Date('01/01/2022');
            wrapper.vm.store.calendar.dateRange.end = new Date('01/15/2022');
            wrapper.vm.store.showOnlyCustomOrderedAssignments = true;
          }
        );

        it('shows the message - there are no assignments', () => {
          expect(wrapper.find('.test-no-assignments-message').isVisible()).toBeTruthy();
        });
      }
    );

    describe('when there are custom ordered assignments and the custom ordered checkbox is selected',
      () => {
        beforeEach(
          () => {
            wrapper.vm.store.calendar.dateRange.start = new Date('01/01/2022');
            wrapper.vm.store.calendar.dateRange.end = new Date('01/20/2022');
            wrapper.vm.store.showOnlyCustomOrderedAssignments = true;
            wrapper.vm.store.customOrderedCount = 1;
          }
        );

        it('does not show the message - there are no assignments', () => {
          expect(wrapper.find('.test-no-assignments-message').isVisible()).toBeFalsy();
        });
      }
    );

    describe('when there are no custom ordered assignments and the custom ordered checkbox is not selected',
      () => {
        beforeEach(
          () => {
            wrapper.vm.store.calendar.dateRange.start = new Date('01/01/2022');
            wrapper.vm.store.calendar.dateRange.end = new Date('01/15/2022');
            wrapper.vm.store.showOnlyCustomOrderedAssignments = false;
            wrapper.vm.store.customOrderedCount = 1;
          }
        );

        it('does not show the message - there are no assignments', () => {
          expect(wrapper.find('.test-no-assignments-message').isVisible()).toBeFalsy();
        });
      }
    );

  }
);
