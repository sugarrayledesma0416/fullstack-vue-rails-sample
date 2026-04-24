import { mount } from '@vue/test-utils';
import AssignmentDay from 'sections/supersites_assignments/AssignmentDay';

const toggleExpanded = jasmine.createSpy('toggleExpanded');

/**
 * Get wrapper for component or an element within it.
 *
 * The optional selector argument is to simplify a common
 * use case in the specs: I would get the wrapper for the
 * component, then immediately call `wrapper.find` on it
 * to get the element for a known selector. I added the
 * selector to DRY the specs and make this method
 * responsible for finding the element, given a selector.
 * @param {Object} objectToMerge - an object with properties
 *   to merge into the default assignmentDay
 * @param {String} selector - optional CSS selector for
 *   element within component
 * @returns {Wrapper} wrapper for the component or element
 */
function getWrapper(objectToMerge, selector) {
  const wrapper = mount(AssignmentDay, {
    propsData: {
      assignmentDay: Object.assign(
        {},
        { due_date: '2020-11-11' },
        objectToMerge
      ),
      index: 0
    },
    global: {
      provide: {
        toggleExpanded
      }
    }
  });

  if (selector == null) { return wrapper; }

  return wrapper.find(selector);
}

describe('AssignmentDay', () => {
  function assignmentDayDiv(objectToMerge) {
    return getWrapper(objectToMerge, '.c-assignment-day');
  }

  describe('expanded state', () => {
    it('has expanded class if day is expanded', () => {
      expect(assignmentDayDiv({ expanded: true }).classes('expanded')).toBe(true);
    });

    it('does not have expanded class if day is not expanded', () => {
      expect(assignmentDayDiv({ expanded: false }).classes('expanded')).toBe(false);
    });
  });

  describe('overdue state', () => {
    it('has overdue class if day is overdue', () => {
      expect(assignmentDayDiv({ overdue: true }).classes('overdue')).toBe(true);
    });

    it('does not have overdue class if day is not overdue', () => {
      expect(assignmentDayDiv({ overdue: false }).classes('overdue')).toBe(false);
    });
  });

  describe('header button', () => {
    function headerButton(objectToMerge) {
      return getWrapper(objectToMerge, '.test-assignment-day-header-0');
    }

    describe('on being clicked', () => {
      it('calls toggleExpanded', async () => {
        const assignmentDay = {
          due_date: '2020-11-11',
          foo: 'bar'
        };

        const button = getWrapper({ foo: 'bar' }, '.test-assignment-day-header-0');
        await button.trigger('click');
        expect(toggleExpanded).toHaveBeenCalledWith(assignmentDay);
      });
    });

    describe('assignment completion state', () => {
      describe('when all assignments are complete for a day', () => {
        it('is hidden', () => {
          expect(headerButton({ all_assignments_completed: true }).isVisible()).toBe(false);
        });
      });

      describe('when not all assignments are complete for a day', () => {
        it('is visible', () => {
          expect(headerButton({ all_assignments_completed: false }).isVisible()).toBe(true);
        });
      });
    });

    describe('aria-expanded', () => {
      it('mirrors assignmentDay.expanded', () => {
        const headerExpanded = headerButton({ expanded: true });
        const headerNotExpanded = headerButton({ expanded: false });

        expect(headerExpanded.attributes('aria-expanded')).toBe('true');
        expect(headerNotExpanded.attributes('aria-expanded')).toBe('false');
      });
    });

    describe('date information', () => {
      describe('when the day is expanded', () => {
        it('shows the minus icon and hides the plus icon', () => {
          const minusIcon = getWrapper({ expanded: true }, '.test-minus-icon-0');
          const plusIcon = getWrapper({ expanded: true }, '.test-plus-icon-0');

          expect(minusIcon.isVisible()).toBe(true);
          expect(plusIcon.isVisible()).toBe(false);
        });
      });

      describe('when the day is not expanded', () => {
        it('shows the plus icon and hides the minus icon', () => {
          const minusIcon = getWrapper({ expanded: false }, '.test-minus-icon-0');
          const plusIcon = getWrapper({ expanded: false }, '.test-plus-icon-0');

          expect(minusIcon.isVisible()).toBe(false);
          expect(plusIcon.isVisible()).toBe(true);
        });
      });

      it('shows the label for the day', () => {
        const wrapper = getWrapper(
          { label: 'Wednesday, November 11th' },
          '.test-assignment-day-label'
        );

        expect(wrapper.text()).toBe('Wednesday, November 11th');
      });

      describe('counts', () => {
        function assignmentCountDiv(objectToMerge, selector) {
          return getWrapper(
            Object.assign(
              {
                due_date_sub_heading: "3 activities",
                total_assignments: 3,
                total_assignments_label: "assignments"
              },
              objectToMerge
            ),
            selector
          );
        }

        describe('when the day is expanded', () => {
          it('shows the expanded count text and hides the not-extended count text', () => {
            const wrapper = assignmentCountDiv(
              { expanded: true },
              '.test-assignment-count-expanded'
            );
            expect(wrapper.text()).toBe('3 activities');
          });
        });

        describe('when the day is not expanded', () => {
          it('hides the expanded count text and shows the not-extended count text', () => {
            const wrapper = assignmentCountDiv(
              { expanded: false },
              '.test-assignment-count-not-expanded'
            );
            expect(wrapper.text()).toBe('3 assignments');
          });
        });
      });
    });
  });

  describe('banks by concept div', () => {
    function banksByConceptDiv(objectToMerge) {
      return getWrapper(objectToMerge, '.test-banks-by-concept');
    }

    it('is hidden when all assignments are complete', () => {
      const wrapper = banksByConceptDiv({ all_assignments_completed: true });
      expect(wrapper.isVisible()).toBe(false);
    });

    it('is shown when not all assignments are complete', () => {
      const wrapper = banksByConceptDiv({ all_assignments_completed: false });
      expect(wrapper.isVisible()).toBe(true);
    });
  });

  describe('no-due-dates section', () => {
    describe('when all work is complete', () => {
      it('includes the no-due-dates section', () => {
        const wrapper = getWrapper(
          { all_assignments_completed: true },
          '.test-no-due-date'
        );

        expect(wrapper.isVisible()).toBe(true);
      });

      it('includes the assignment-day label', () => {
        const wrapper = getWrapper(
          {
            all_assignments_completed: true,
            expanded: true,
            label: 'Wednesday, November 11th'
          },
          '.test-day-label'
        );

        expect(wrapper.text()).toBe('Wednesday, November 11th');
      });

      describe('month-day div', () => {
        function monthDayDiv(objectToMerge) {
          return getWrapper(
            Object.assign(
              {
                all_assignments_completed: true,
                label: 'Wednesday, November 11th'
              },
              objectToMerge
            ),
            '.test-month-day'
          );
        }

        describe('when day is expanded', () => {
          it('shows abbreviated date', () => {
            const wrapper = monthDayDiv({ expanded: true });
            expect(wrapper.isVisible()).toBe(true);
            expect(wrapper.text()).toBe('Nov11');
          });
        });

        describe('when day is not expanded', () => {
          it('shows the expected text', () => {
            const wrapper = monthDayDiv({ expanded: false });
            expect(wrapper.isVisible()).toBe(false);
          });
        });
      });
    });

    describe('when not all work is complete', () => {
      it('skips the no-due-dates section', () => {
        const wrapper = getWrapper(
          { all_assignments_completed: false },
          '.test-no-due-date'
        );

        expect(wrapper.isVisible()).toBe(false);
      });
    });
  });

  describe('zero-activities div', () => {
    function zeroActivitiesDiv(objectToMerge) {
      return getWrapper(objectToMerge, '.test-zero-activities');
    }

    describe('when all work is complete', () => {
      it('shows the zero-activities div', () => {
        const wrapper = zeroActivitiesDiv({ all_assignments_completed: true });
        expect(wrapper.isVisible()).toBe(true);
      });
    });

    describe('when not all work is complete', () => {
      it('hides the zero-activities div', () => {
        const wrapper = zeroActivitiesDiv({ all_assignments_completed: false });
        expect(wrapper.isVisible()).toBe(false);
      });
    });
  });
});
