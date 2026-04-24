import { setActivePinia, createPinia } from 'pinia';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';
import useAssignmentSetStore
  from 'features/assignment_sets_calendar/models/use_assignment_set_store';
import { dateFromCourseDateString } from 'shared/date_utils';

import MockDate from 'mockdate';
MockDate.set(new Date(2022, 6, 1));

describe(
  'useAssignmentSetStore',
  () => {
    const endpointUrl = 'valid/endpoint';
    const putEndpointUrl = endpointUrl + '/1234';
    const csvUrl = 'valid/csv/endpoint';

    const assignmentSetsDefaultOrder = [
      {
        activities: [{ activity_title: 'foo' }, { activity_title: 'bar' }],
        due_date: '2022-07-01',
        dueDateAsDate: dateFromCourseDateString('2022-07-01'),
      },
    ];

    const assignmentSets = [
      {
        activities: [{ activity_title: 'bar' }, { activity_title: 'foo' }],
        due_date: '2022-07-01',
        dueDateAsDate: dateFromCourseDateString('2022-07-01'),
        id: 1,
      },
    ];

    const courseStartDate = new Date(2022, 0, 1);
    const courseEndDate = new Date(2022, 7, 1);
    const calendarForComponent = {
      dateRange: {
        start: new Date(2022, 6, 1),
        end: new Date(2022, 6, 31),
      },
      attributes: [{
        dates: [
          { start: courseStartDate, end: new Date(2022, 0, 1) },
          { start: courseEndDate, end: new Date(2022, 7, 31) },
        ],
        popover: {
          label: 'Date must be between the course start and end date.',
          visibility: 'click',
        },
      }],
      courseStartDate: new Date(2022, 0, 1),
      courseEndDate: new Date(2022, 7, 1),
    };

    let store;
    let courseStartDateString = '';
    let courseEndDateString = '';

    beforeEach(
      () => {
        setActivePinia(createPinia());
        store = useAssignmentSetStore();
        courseStartDateString = '2022-01-01';
        courseEndDateString = '2022-08-01';
      }
    );

    describe(
      'init',
      () => {
        it(
          'assigns the specified assignmentSets, endpointUrl, csvUrl ' +
          'and calendar to the state',
          () => {
            store.init(
              assignmentSets,
              assignmentSetsDefaultOrder,
              endpointUrl,
              csvUrl,
              courseStartDateString,
              courseEndDateString
            );

            const expectedDate = dateFromCourseDateString(assignmentSets[0].due_date);
            expect(store.assignmentSets[0].dueDateAsDate).toEqual(expectedDate);
            expect(store.assignmentSetsDefaultOrder[0].hasCustomOrder).toEqual(false);
            expect(store.endpointUrl).toBe(endpointUrl);
            expect(store.csvUrl).toBe(csvUrl);
            expect(store.calendar).toEqual(calendarForComponent);
          }
        );

        it(
          'sets the hasCustomOrder property of each assignment set based ' +
          'on whether or not it has an id',
          () => {
            const assignmentSetsWithCustom = [
              { due_date: '2022-06-01' },
              { id: 1, due_date: '2022-06-02' },
            ];

            store.init(
              assignmentSetsWithCustom,
              assignmentSetsDefaultOrder,
              endpointUrl,
              csvUrl,
              courseStartDateString,
              courseEndDateString
            );

            expect(store.assignmentSets[0].hasCustomOrder).toBeFalsy();
            expect(store.assignmentSets[1].hasCustomOrder).toBeTruthy();
          }
        );
      }
    );

    describe('revertToDefaultOrder', () => {
      it('sets the assignment set list to the default order',
        () => {
          store.init(
            assignmentSets,
            assignmentSetsDefaultOrder,
            endpointUrl,
            csvUrl,
            courseStartDateString,
            courseEndDateString
          );
          store.revertToDefaultOrder(store.assignmentSets[0]);
          expect(store.assignmentSets[0].hasCustomOrder).toEqual(false);
          expect(store.assignmentSets[0].id).toEqual(null);
          const originalActivityOrder =
                store.assignmentSetsDefaultOrder[0].activities.map((elm) => elm.activity_title);
          expect(
            store.assignmentSets[0].activities.map((elm) => elm.activity_title)
          ).toEqual(originalActivityOrder);
        }
      );
    });

    describe(
      'csvExportUrl',
      () => {
        it(
          'returns the specified csvUrl with added query parameters for ' +
          'the desired start and end dates in YYYY-MM-DD format',
          () => {
            store.init(
              [],
              [],
              endpointUrl,
              csvUrl,
              courseStartDateString,
              courseEndDateString
            );

            expect(store.csvExportUrl).toEqual(
              'valid/csv/endpoint?start_date=2022-07-01&end_date=2022-07-31'
            );
          }
        );
      }
    );

    describe(
      'saveSet',
      () => {
        beforeEach(
          () => {
            spyOn(ajaxUtils, 'putToEndpoint').and.callThrough();
            fetchMock.mock(putEndpointUrl, { status: 200 });

            spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();
            fetchMock.mock(
              endpointUrl,
              { body: { assignment_set: { id: 2345 }}, status: 200 }
            );
          }
        );

        afterEach(() => fetchMock.restore());

        describe(
          'when the specified assignmentSet has an id',
          () => {
            it(
              'sends a PUT request with the assignmentSet data to the ' +
              'endpointUrl suffixed with the assignmentSet id',
              () => {
                const assignmentSet = { due_date: 'friday', id: 1234 };

                store.init(
                  [],
                  [],
                  endpointUrl,
                  csvUrl,
                  courseStartDateString,
                  courseEndDateString
                );

                store.saveSet(assignmentSet);

                expect(ajaxUtils.putToEndpoint).toHaveBeenCalledWith(
                  putEndpointUrl,
                  { assignment_set: assignmentSet },
                  jasmine.any(Function)
                );
              }
            );
          }
        );

        describe(
          'when the specified assignmentSet has no id',
          () => {
            it(
              'sends a POST request with the assignmentSet data to the ' +
              'endpointUrl',
              () => {
                const assignmentSet = { due_date: 'friday' };

                store.init(
                  [],
                  [],
                  endpointUrl,
                  csvUrl,
                  courseStartDateString,
                  courseEndDateString
                );

                store.saveSet(assignmentSet);

                expect(ajaxUtils.postToEndpoint).toHaveBeenCalledWith(
                  endpointUrl,
                  { assignment_set: assignmentSet },
                  jasmine.any(Function)
                );
              }
            );

            it(
              'updates the assignmentSet with the id from the response',
              async () => {
                const assignmentSet = { due_date: 'friday' };

                store.init(
                  [],
                  [],
                  endpointUrl,
                  csvUrl,
                  courseStartDateString,
                  courseEndDateString
                );

                store.saveSet(assignmentSet);
                await fetchMock.flush(true);

                expect(assignmentSet.id).toBe(2345);
              }
            );
          }
        );
      }
    );
  }
);
