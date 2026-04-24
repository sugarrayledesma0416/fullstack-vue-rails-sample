import { mount } from '@vue/test-utils';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';
import AssignmentsApp from 'sections/supersites_assignments/AssignmentsApp';
import flushPromises from 'flush-promises';

function getWrapper(data) {
  return mount(AssignmentsApp);
}

const assignmentDayUrl = 'new_dashboard/assignments/';

describe('AssignmentsApp', () => {
  describe('spinner show/hide', () => {
    beforeEach(() => {
      /* Mock the fetch call. */
      let jsonResponse = [];
      fetchMock.mock(assignmentDayUrl, { status: 200, body: jsonResponse });
    });

    afterEach(()=> {
      fetchMock.restore();
    });

    describe('when state.dataLoaded is false', () => {
      it('shows the spinner', () => {
        const wrapper = getWrapper();

        /**
         * On being mounted, the component will make an AJAX request;
         *   when the promise for that request is resolved, the state
         *   will be updated to hide the spinner. A spec that tests
         *   the component's behavior after the promise is resolved
         *   normally will call `flushPromises()` to resolve the
         *   AJAX-request promise.
         *
         * This spec deliberately does not call flushPromises() to resolve
         *   the promise, however, so that it can assert the component's
         *   visible state before the AJAX request is complete.
         */
        expect(wrapper.find('.test-spinner').isVisible()).toBe(true);
      });
    });

    describe('when state.dataLoaded is true', () => {
      it('hides the spinner', async () => {
        const wrapper = getWrapper();
        /**
         * Resolve the promise for the AJAX request so that the spec can
         *  assert the component's visible state after the request is complete.
         *
         * @see {@link https://www.npmjs.com/package/flush-promises|flush-promises}
         */
        await flushPromises();
        expect(wrapper.find('.test-spinner').isVisible()).toBe(false);
      });
    });
  });

  describe('retrieving assignment-day data', () => {
    let jsonResponse;

    beforeEach(() => {
      /* Mock the fetch call. */
      jsonResponse = [
        {
          "label": "Overdue",
          "expanded": false,
          "overdue": true,
          "total_assignments": 5,
          "total_assignments_label": "assignments",
          "due_date": "overdue",
          "assignment_groups": [
            {
              "total_assignments": 5,
              "total_label_pluralized": "activities",
              "due_time": "Due 11:59 PM",
              "time_zone": null,
              "estimate_time": "23m",
              "url": "/sections/1/assignments/overdue",
              "can_be_started": true,
              "assignment_banks": [
                {
                  "style": "{'border-left': '0.25rem solid #FF0000'}",
                  "lesson_label": "Lección 1",
                  "concept_name": "<b>Contextos</b>",
                  "assessment_id": 1,
                  "availability_message": "This assessment will be available when your instructor releases it",
                  "activity_count_text": "5 activities"
                }
              ]
            }
          ],
          "all_assignments_completed": false,
          "course_show_estimated_times": true,
          "due_date_sub_heading": "5 activities"
        },
        /* All assignments complete */
        {
          "label": "Wednesday, November 4th",
          "expanded": true,
          "overdue": false,
          "total_assignments": 3,
          "total_assignments_label": "assignments",
          "due_date": "2020-11-04",
          "assignment_groups": [
            {
              "total_assignments": 3,
              "total_label_pluralized": "activities",
              "due_time": "Due 11:59 PM",
              "time_zone": null,
              "estimate_time": "12m",
              "url": "/sections/1/assignments/2020-11-04",
              "can_be_started": true,
              "assignment_banks": [
                {
                  "style": "{'border-left': '0.25rem solid #FF0000'}",
                  "lesson_label": "Lección 1",
                  "concept_name": "<b>Contextos</b>",
                  "assessment_id": 2,
                  "availability_message": "This assessment will be available when your instructor releases it",
                  "activity_count_text": "3 activities"
                }
              ]
            }
          ],
          "all_assignments_completed": true,
          "course_show_estimated_times": true,
          "due_date_sub_heading": "3 activities"
        },
        {
          "label": "Friday, November 6th",
          "expanded": false,
          "overdue": false,
          "total_assignments": 3,
          "total_assignments_label": "assignments",
          "due_date": "2020-11-06",
          "assignment_groups": [
            {
              "total_assignments": 3,
              "total_label_pluralized": "activities",
              "due_time": "Due 11:59 PM",
              "time_zone": null,
              "estimate_time": "24m",
              "url": "/sections/i/assignments/2020-11-06",
              "can_be_started": true,
              "assignment_banks": [
                {
                  "style": "{'border-left': '0.25rem solid #FF0000'}",
                  "lesson_label": "Lección 1",
                  "concept_name": "<b>Contextos</b>",
                  "assessment_id": 3,
                  "availability_message": "This assessment will be available when your instructor releases it",
                  "activity_count_text": "3 activities"
                }
              ]
            }
          ],
          "all_assignments_completed": false,
          "course_show_estimated_times": true,
          "due_date_sub_heading": "3 activities"
        }
      ];
      fetchMock.mock(assignmentDayUrl, { status: 200, body: jsonResponse });
    });

    afterEach(()=> {
      fetchMock.restore();
    });

    describe('when the app is mounted', () => {
      it('requests assignment-day data', () => {
        spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
        const wrapper = getWrapper();
        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          assignmentDayUrl,
          jasmine.any(Function)
        );
      });
    });

    describe('after assignment days are retrieved', () => {
      describe('initially expanding assignment days', () => {
        describe('when there are future due dates', () => {
          it('expands only the future due date marked as expanded', async () => {
            const wrapper = getWrapper();
            await flushPromises();
            const assignmentDayDivs = wrapper.findAll('.c-assignment-day');
            expect(assignmentDayDivs[0].classes('expanded')).toBe(false);
            expect(assignmentDayDivs[1].classes('expanded')).toBe(true);
          });
        });

        describe('when there are no future due dates', () => {
          it('expands late work', async () => {
            fetchMock.restore();
            let onlyOverdueResponse = [ jsonResponse[0] ];
            fetchMock.mock(assignmentDayUrl, { status: 200, body: onlyOverdueResponse });
            const wrapper = getWrapper();
            await flushPromises();
            expect(wrapper.find('.c-assignment-day').classes('expanded')).toBe(true);
          });
        });
      });
    });

    describe('manually expanding/contracting assignment days', () => {
      describe('when the user clicks to expand an assignment day', () => {
        let assignmentDayDivs, wrapper;

        beforeEach(async () => {
          wrapper = getWrapper();
          await flushPromises();
          assignmentDayDivs = wrapper.findAll('.c-assignment-day');
          let headerButton = wrapper.find('.test-assignment-day-header-2');
          await headerButton.trigger('click');
        });

        it('expands the assignment day', () => {
          expect(assignmentDayDivs[2].classes('expanded')).toBe(true);
        });

        it('contracts all other assignment days', () => {
          expect(assignmentDayDivs[0].classes('expanded')).toBe(false);
          expect(assignmentDayDivs[1].classes('expanded')).toBe(false);
        });
      });
    });
  });
});
