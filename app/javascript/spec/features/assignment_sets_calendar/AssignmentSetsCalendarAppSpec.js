import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import AssignmentSetsCalendarApp from 'features/assignment_sets_calendar/AssignmentSetsCalendarApp';
import MockDate from 'mockdate';

MockDate.set(new Date(2022, 7, 15));

const assignmentSets = JSON.stringify(
  {
    custom_order:
  [
    {
      due_date: '2022-07-01',
      dueDateAsDate: new Date(),
      hasCustomOrder: false,
    },
  ],
    default_order:
    [
      {
        due_date: '2022-07-01',
        dueDateAsDate: new Date(),
        hasCustomOrder: false,
      },
    ]
  }
);

let courseStartDateSets;
let courseEndDateSets;

describe(
  'AssignmentSetsCalendarApp',
  () => {
    let wrapper;
    function getWrapper() {
      return mount(
        AssignmentSetsCalendarApp,
        {
          global: {
            plugins: [
              createTestingPinia(
                {
                  stubActions: false,
                  initialState: {
                    store: {
                      assignmentSets: [],
                      assignmentSetsDefaultOrder: [],
                      calendar: {
                        dateRange: {
                          start: null,
                          end: null,
                        },
                        attributes: [],
                        courseStartDate: null,
                        courseEndDate: null,
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
          props: {
            assignments: assignmentSets,
            courseStartDate: courseStartDateSets,
            courseEndDate: courseEndDateSets,
            csvUrl: '',
            endpointUrl: '',
          },
        }
      );
    }

    function setInputAndBlur(selector, value) {
      const input = wrapper.find(selector);
      input.setValue(value);
      input.trigger('blur');
    }

    // Return date under the format YY-MM-DD
    function setFormatDate(date) {
      const year = date.getUTCFullYear();
      let month = date.getUTCMonth() + 1;
      let day = date.getUTCDate();

      month = month < 10 ? '0' + month : month;
      day = day < 10 ? '0' + day : day;

      return year + '-' + month + '-' + day;
    }

    function addDaysToDate(numDays) {
      return setFormatDate(
        new Date(
          new Date().setDate(new Date().getDate() + numDays)
        )
      );
    }


    beforeEach(
      () => {
        courseStartDateSets = '2022-01-01';
        courseEndDateSets = '2022-09-14';
        wrapper = getWrapper();
      }
    );

    describe(
      'initial values for manual date range',
      () => {
        it(
          'initializes with the start date defined in the store calendar',
          () => {
            const start = new Date(wrapper.vm.store.calendar.dateRange.start);
            const inputDate = new Date(wrapper.find('.test-start-date-input').element.value);
            expect(start.toString() === inputDate.toString()).toBe(true);
          }
        );

        it(
          'initializes with the end date defined in the store calendar',
          () => {
            const end = new Date(wrapper.vm.store.calendar.dateRange.end);
            const inputDate = new Date(wrapper.find('.test-end-date-input').element.value);
            expect(end.toString() === inputDate.toString()).toBe(true);
          }
        );
      }
    );
    describe(
      'when the user changes the date range manually',
      () => {
        let initStartDate;
        beforeEach(
          () => {
            initStartDate = new Date(wrapper.vm.store.calendar.dateRange.start).toString();
            wrapper.find('.test-pattern-msg').element.setAttribute('style', 'display: none;');
            wrapper.find('.test-range-msg').element.setAttribute('style', 'display: none;');
          }
        );

        it(
          'does not allow letters',
          async () => {
            await setInputAndBlur('.test-start-date-input', 'blah');

            // confirm validation msg displays
            expect(wrapper.find('.test-pattern-msg').isVisible()).toBe(true);

            // confirm input val reverts when value is invalid
            const currentInputStartDate = new Date(
              wrapper.find('.test-start-date-input').element.value
            ).toString();
            expect(currentInputStartDate).toEqual(initStartDate);

            // confirm model does not update when input date is invalid
            const currentStartDate = new Date(wrapper.vm.store.calendar.dateRange.start).toString();
            expect(initStartDate).toEqual(currentStartDate);
          }
        );

        it(
          'does not allow non-leading zeros for month',
          async () => {
            await setInputAndBlur('.test-start-date-input', '1/02/2022');
            expect(wrapper.find('.test-pattern-msg').isVisible()).toBe(true);
          }
        );

        it(
          'does not allow non-leading zeros for day',
          async () => {
            await setInputAndBlur('.test-start-date-input', '01/1/2022');
            expect(wrapper.find('.test-pattern-msg').isVisible()).toBe(true);
          }
        );

        it(
          'does not allow non-4 char year',
          async () => {
            await setInputAndBlur('.test-start-date-input', '01/01/22');
            expect(wrapper.find('.test-pattern-msg').isVisible()).toBe(true);
          }
        );

        it(
          'does not allow extra stuff at the beginning of a valid date',
          async () => {
            await setInputAndBlur('.test-start-date-input', 'a01/01/2022');
            expect(wrapper.find('.test-pattern-msg').isVisible()).toBe(true);
          }
        );

        it(
          'does not allow extra stuff at the end of a valid date',
          async () => {
            await setInputAndBlur('.test-start-date-input', '01/01/2022a');
            expect(wrapper.find('.test-pattern-msg').isVisible()).toBe(true);
          }
        );

        it(
          'does not allow dash separators',
          async () => {
            await setInputAndBlur('.test-start-date-input', '01-01-2022');
            expect(wrapper.find('.test-pattern-msg').isVisible()).toBe(true);
          }
        );

        it(
          'allows a valid date string',
          async () => {
            await setInputAndBlur('.test-start-date-input', '01/02/2022');
            expect(wrapper.find('.test-pattern-msg').isVisible()).toBe(false);
            expect(wrapper.find('.test-range-msg').isVisible()).toBe(false);
            expect(wrapper.find('.id-2022-01-02').get('.vc-highlight-base-start')).toBeTruthy();
          }
        );

        it(
          'allows a valid end date',
          async () => {
            await setInputAndBlur('.test-end-date-input', '09/14/2022');
            expect(wrapper.find('.test-pattern-msg').isVisible()).toBe(false);
            expect(wrapper.find('.test-range-msg').isVisible()).toBe(false);
          }
        );

        it(
          'does not allow dates before course start',
          async () => {
            await setInputAndBlur('.test-start-date-input', '01/01/2021');

            // confirm validation msg displays
            expect(wrapper.find('.test-range-msg').isVisible()).toBe(true);

            // confirm input val reverts when value is invalid
            const currentInputStartDate = new Date(
              wrapper.find('.test-start-date-input').element.value
            ).toString();
            expect(currentInputStartDate).toEqual(initStartDate);

            // confirm model does not update when input date is invalid
            const currentStartDate = new Date(wrapper.vm.store.calendar.dateRange.start).toString();
            expect(initStartDate).toEqual(currentStartDate);
          }
        );

        it(
          'does not allow dates after course end',
          async () => {
            await setInputAndBlur('.test-start-date-input', '09/15/2022');
            expect(wrapper.find('.test-range-msg').isVisible()).toBe(true);
          }
        );
      }
    );

    describe('when the user clicks a pre-selected date range button', () => {
      it('sets the calendar for the course range for the show all button', () => {
        const button = wrapper.find('.test-pre-set-show-all-button');

        const startPreSetDate = wrapper.vm.props.courseStartDate;
        const endPreSetDate = wrapper.vm.props.courseEndDate;

        button.trigger('click');

        const startDate = setFormatDate(wrapper.vm.store.calendar.dateRange.start);
        const endDate = setFormatDate(wrapper.vm.store.calendar.dateRange.end);

        // Take only the date under the format YY-MM-DD to compare
        expect(startPreSetDate).toEqual(startDate);
        expect(endPreSetDate).toEqual(endDate);
      });

      describe('when the 7 day button is clicked', () => {
        it('sets the calendar for the next 7 days for the 7 day button',
          () => {
            const button = wrapper.find('.test-pre-set-seven-days-button');

            const startPreSetDate = setFormatDate(new Date());
            const endPreSetDate = addDaysToDate(7);

            button.trigger('click');

            const startDate = setFormatDate(wrapper.vm.store.calendar.dateRange.start);
            const endDate = setFormatDate(wrapper.vm.store.calendar.dateRange.end);

            // Take only the date under the format YY-MM-DD to compare
            expect(startPreSetDate).toEqual(startDate);
            expect(endPreSetDate).toEqual(endDate);
          });

        it('displays a validation message if the course ends before the next 7 days', async () => {
          courseStartDateSets = setFormatDate(new Date());
          courseEndDateSets = addDaysToDate(5);
          wrapper = getWrapper();

          const button = wrapper.find('.test-pre-set-seven-days-button');

          await button.trigger('click');

          const startDate = setFormatDate(wrapper.vm.store.calendar.dateRange.start);
          const endDate = setFormatDate(wrapper.vm.store.calendar.dateRange.end);

          // Take only the date under the format YY-MM-DD to compare
          expect(courseStartDateSets).toEqual(startDate);
          expect(courseEndDateSets).toEqual(endDate);
          expect(wrapper.find('.test-range-msg').isVisible()).toBe(true);
        });
      });

      describe('when the 30 day button is clicked', () => {
        it('sets the calendar for the next 30 days for the 30 day button', () => {
          const button = wrapper.find('.test-pre-set-thirty-days-button');

          const startPreSetDate = setFormatDate(new Date());

          const endPreSetDate = addDaysToDate(30);

          button.trigger('click');

          const startDate = setFormatDate(wrapper.vm.store.calendar.dateRange.start);
          const endDate = setFormatDate(wrapper.vm.store.calendar.dateRange.end);

          // Take only the date under the format YY-MM-DD to compare
          expect(startPreSetDate).toEqual(startDate);
          expect(endPreSetDate).toEqual(endDate);
        });

        it('displays a validation message if the course ends before the next 30 days', async () => {
          courseStartDateSets = setFormatDate(new Date());
          courseEndDateSets = addDaysToDate(7);
          wrapper = getWrapper();

          const button = wrapper.find('.test-pre-set-thirty-days-button');

          await button.trigger('click');

          const startDate = setFormatDate(wrapper.vm.store.calendar.dateRange.start);
          const endDate = setFormatDate(wrapper.vm.store.calendar.dateRange.end);

          // Take only the date under the format YY-MM-DD to compare
          expect(courseStartDateSets).toEqual(startDate);
          expect(courseEndDateSets).toEqual(endDate);
          expect(wrapper.find('.test-range-msg').isVisible()).toBe(true);
        });
      });
    });
  });
