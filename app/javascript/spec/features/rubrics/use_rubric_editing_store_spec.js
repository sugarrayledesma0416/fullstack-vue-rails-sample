import { setActivePinia, createPinia } from 'pinia';
import useRubricEditingStore from 'features/rubrics/use_rubric_editing_store';
import * as fs from 'fs';
import * as path from 'path';

describe(
  'useRubricEditingStore',
  () => {
    let store;
    let initialRubricObject;
    let initialRubricJson;

    beforeEach(
      () => {
        setActivePinia(createPinia());
        store = useRubricEditingStore();

        initialRubricObject = {
          show_score: true,
          header_row: {
            HeaderRow: {
              header_columns: [
                { id: '1', label: 'old_header_1_label' },
                { id: '2', label: 'old_header_2_label' },
              ],
            },
          },
          criterias: [
            {
              Criteria: {
                title: 'old_title_1',
                performances: [
                  {
                    header_id: '1',
                    description: 'col_1_row_1_old_desc',
                    score: 100,
                  },
                  {
                    header_id: '2',
                    description: 'col_2_row_1_old_desc',
                    score: 100,
                  },
                ],
              },
            },
            {
              Criteria: {
                title: 'old_title_2',
                performances: [
                  {
                    header_id: '1',
                    description: 'col_1_row_2_old_desc',
                    score: 100,
                  },
                  {
                    header_id: '2',
                    description: 'col_2_row_2_old_desc',
                    score: 100,
                  },
                ],
              },
            },
          ],
        };

        initialRubricJson = JSON.stringify(initialRubricObject);
      }
    );

    describe(
      'cancelEditingCriterion',
      () => {
        let criterion1;

        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            criterion1 = store.content.criterias[0].Criteria;
            store.startEditingCriterion(criterion1);
          }
        );

        it(
          'sets the criterionToEdit property to null',
          () => {
            store.cancelEditingCriterion();

            expect(store.criterionToEdit).toBeNull();
          }
        );

        it(
          'sets the unsavedCriterion property to an empty object',
          () => {
            store.cancelEditingCriterion();

            expect(store.unsavedCriterion).toEqual({});
          }
        );

        it(
          'clears any validation errors',
          () => {
            store.validationError = 'something';
            store.cancelEditingCriterion();

            expect(store.errorValidatorCount).toEqual(0);
          }
        );
      }
    );

    describe(
      'cancelEditingHeader',
      () => {
        let header1;

        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            header1 = store.content.header_row.HeaderRow.header_columns[0];
            store.startEditingHeader(header1);
          }
        );

        it(
          'sets the headerToEdit property to null',
          () => {
            store.cancelEditingHeader();

            expect(store.headerToEdit).toBeNull();
          }
        );

        it(
          'sets the unsavedHeader property to an empty object',
          () => {
            store.cancelEditingHeader();

            expect(store.unsavedHeader).toEqual({});
          }
        );

        it(
          'clears any validation errors',
          () => {
            store.validationError = 'something';
            store.cancelEditingHeader();

            expect(store.errorValidatorCount).toEqual(0);
          }
        );
      }
    );


    describe(
      'cancelEditingPerformance',
      () => {
        let performance1;

        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            performance1 = store.content.criterias[0].Criteria.performances[0];
            store.startEditingPerformance(performance1);
          }
        );

        it(
          'sets the performanceToEdit property to null',
          () => {
            store.cancelEditingPerformance();

            expect(store.performanceToEdit).toBeNull();
          }
        );

        it(
          'sets the unsavedPerformance property to an empty object',
          () => {
            store.cancelEditingPerformance();

            expect(store.unsavedPerformance).toEqual({});
          }
        );

        it(
          'clears any validation errors',
          () => {
            store.validationError = 'something';
            store.cancelEditingPerformance();

            expect(store.errorValidatorCount).toEqual(0);
          }
        );
      }
    );

    describe(
      'init',
      () => {
        let initialRubricObjectNew;
        it(
          'parses the specified JSON and stores it in the content property',
          () => {
            store.init({ rubricJson: initialRubricJson });

            expect(store.content).toEqual(initialRubricObject);
          }
        );

        it(
          'does not change lastAddedRowNumber',
          () => {
            store.init({ rubricJson: initialRubricJson });

            expect(store.lastAddedRowNumber).toEqual(1);
          }
        );

        it(
          'does not change lastAddedColumnNumber',
          () => {
            store.init({ rubricJson: initialRubricJson });

            expect(store.lastAddedColumnNumber).toEqual(1);
          }
        );

        it(
          'parses the specified JSON and stores when there is an existing new row',
          () => {
            initialRubricObjectNew = {
              show_score: true,
              header_row: {
                HeaderRow: {
                  header_columns: [
                    { id: '1', label: 'old_header_1_label' },
                  ],
                },
              },
              criterias: [
                {
                  Criteria: {
                    title: 'New row 1',
                    performances: [
                      {
                        header_id: '1',
                        description: 'col_1_row_1_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
                {
                  Criteria: {
                    title: 'old_title_2',
                    performances: [
                      {
                        header_id: '1',
                        description: 'col_1_row_2_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
              ],
            };
            store.init({ rubricJson: JSON.stringify(initialRubricObjectNew) });
            expect(store.lastAddedRowNumber).toEqual(2);
          }
        );

        it(
          'parses the specified JSON and stores when there is an existing new column',
          () => {
            initialRubricObjectNew = {
              show_score: true,
              header_row: {
                HeaderRow: {
                  header_columns: [
                    { id: '2', label: 'New column 1' },
                    { id: '1', label: 'old_header_1_label' },
                  ],
                },
              },
              criterias: [
                {
                  Criteria: {
                    title: 'old_title_1',
                    performances: [
                      {
                        header_id: '2',
                        description: 'Edit description and points',
                        score: 1,
                      },
                      {
                        header_id: '1',
                        description: 'col_1_row_1_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
              ],
            };
            store.init({ rubricJson: JSON.stringify(initialRubricObjectNew) });
            expect(store.lastAddedColumnNumber).toEqual(2);
          }
        );
      }
    );

    describe(
      'hasChanges',
      () => {
        let criterion1;
        let performance1;

        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            criterion1 = store.content.criterias[0].Criteria;
            performance1 = criterion1.performances[0];
          }
        );

        it(
          'returns false if no edits have been made',
          () => {
            expect(store.hasChanges).toBeFalsy();
          }
        );

        it(
          'returns true if edits have been made',
          () => {
            performance1.description = 'new description';
            expect(store.hasChanges).toBeTruthy();
          }
        );

        it(
          'returns false if an object is replaced with an object with ' +
          'equal values',
          () => {
            criterion1.performances[0] = { ...performance1 };

            expect(store.hasChanges).toBeFalsy();
          }
        );

        it(
          'returns false if an object is replaced with an object with ' +
          'equal values but the keys in a different order',
          () => {
            const newPerformance = {};

            Object.keys(performance1).reverse().forEach(
              (key) => newPerformance[key] = performance1[key]
            );
            criterion1.performances[0] = newPerformance;

            expect(store.hasChanges).toBeFalsy();
          }
        );
      }
    );

    describe(
      'totalPoints',
      () => {
        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
          }
        );

        it(
          'returns total point for a rubric',
          () => {
            expect(store.totalPoints).toEqual(200);
          }
        );
      }
    );

    describe(
      'saveCriterionEdits',
      () => {
        let criterion1;

        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            criterion1 = store.content.criterias[0].Criteria;
            store.startEditingCriterion(criterion1);
          }
        );

        it(
          'clears any previous validation errors',
          () => {
            store.validationError = 'something';
            store.saveCriterionEdits();

            expect(store.errorValidatorCount).toEqual(0);
          }
        );

        describe(
          'if the unsavedCriterion is valid',
          () => {
            beforeEach(
              () => {
                store.unsavedCriterion.title = 'new_title';
                store.saveCriterionEdits();
              }
            );

            it(
              'updates the title in the original criterion',
              () => {
                expect(criterion1.title).toEqual('new_title');
              }
            );

            it(
              'sets the criterionToEdit property to null',
              () => {
                expect(store.criterionToEdit).toBeNull();
              }
            );

            it(
              'sets the unsavedCriterion property to an empty object',
              () => {
                expect(store.unsavedCriterion).toEqual({});
              }
            );
          }
        );

        function expectCriterionValidationFailure(cell, messages) {
          expect(store.validationError[cell]).toEqual(messages);
          expect(store.criterionToEdit).not.toBeNull();
          expect(store.unsavedCriterion).not.toEqual({});
        }

        describe(
          'if the unsavedCriterion title is blank',
          () => {
            beforeEach(
              () => {
                store.unsavedCriterion.title = '';
                store.saveCriterionEdits();
              }
            );

            it(
              'sets a validation error message and does not exit editing mode',
              () => {
                expectCriterionValidationFailure(
                  'cellCriterionTitle',
                  ['Title cannot be blank']
                );
              }
            );

            it(
              'does not update the title in the original criterion',
              () => {
                expect(criterion1.title).toEqual('old_title_1');
              }
            );
          }
        );

        describe(
          'if the unsavedCriterion title is not unique',
          () => {
            beforeEach(
              () => {
                store.unsavedCriterion.title = 'old_title_2';
                store.saveCriterionEdits();
              }
            );

            it(
              'sets a validation error message and does not exit editing mode',
              () => {
                expectCriterionValidationFailure(
                  'cellCriterionTitle',
                  ['Title must be unique']
                );
              }
            );

            it(
              'does not update the title in the original criterion',
              () => {
                expect(criterion1.title).toEqual('old_title_1');
              }
            );
          }
        );

        describe(
          'if the unsavedCriterion title is a case insensitive match for ' +
          'for another criterion',
          () => {
            beforeEach(
              () => {
                store.unsavedCriterion.title = 'Old_Title_2';
                store.saveCriterionEdits();
              }
            );

            it(
              'sets a validation error message and does not exit editing mode',
              () => {
                expectCriterionValidationFailure(
                  'cellCriterionTitle',
                  ['Title must be unique']
                );
              }
            );

            it(
              'does not update the title in the original criterion',
              () => {
                expect(criterion1.title).toEqual('old_title_1');
              }
            );
          }
        );
      }
    );

    describe(
      'savePerformanceEdits',
      () => {
        let performance1;

        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            performance1 = store.content.criterias[0].Criteria.performances[0];
            store.startEditingPerformance(performance1);
          }
        );

        it(
          'clears any previous validation errors',
          () => {
            store.validationError = 'something';
            store.savePerformanceEdits();

            expect(store.errorValidatorCount).toEqual(0);
          }
        );

        describe(
          'if the unsavedPerformance is valid',
          () => {
            beforeEach(
              () => {
                store.unsavedPerformance.description = 'new_description';
                store.unsavedPerformance.score = 200;
                store.savePerformanceEdits();
              }
            );

            it(
              'updates the description in the original performance',
              () => {
                expect(performance1.description).toEqual('new_description');
              }
            );

            it(
              'updates the score in the original performance',
              () => {
                expect(performance1.score).toEqual(200);
              }
            );

            it(
              'sets the performanceToEdit property to null',
              () => {
                expect(store.performanceToEdit).toBeNull();
              }
            );

            it(
              'sets the unsavedPerformance property to an empty object',
              () => {
                expect(store.unsavedPerformance).toEqual({});
              }
            );
          }
        );

        function expectPerformanceValidationFailure(cell, message) {
          expect(store.validationError[cell]).toEqual(message);
          expect(store.performanceToEdit).not.toBeNull();
          expect(store.unsavedPerformance).not.toEqual({});
        }

        describe(
          'if the unsavedPerformance description is blank',
          () => {
            beforeEach(
              () => {
                store.unsavedPerformance.description = '';
                store.unsavedPerformance.score = 200;
                store.savePerformanceEdits();
              }
            );

            it(
              'sets a validation error message and does not exit editing mode',
              () => {
                expectPerformanceValidationFailure(
                  'cellDescription',
                  ['Description cannot be blank']
                );
              }
            );

            it(
              'does not update the description in the original performance',
              () => {
                expect(performance1.description).toEqual('col_1_row_1_old_desc');
              }
            );

            it(
              'does not update the score in the original performance',
              () => {
                expect(performance1.score).toEqual(100);
              }
            );
          }
        );

        describe(
          'validation of points',
          () => {
            beforeEach(
              () => {
                store.unsavedPerformance.description = 'new_description';
              }
            );

            it(
              'fails validation if a blank score is provided',
              () => {
                store.unsavedPerformance.score = '';
                store.savePerformanceEdits();
                expectPerformanceValidationFailure(
                  'cellScore',
                  ['Points cannot be blank']
                );
                expect(performance1.description).toEqual('col_1_row_1_old_desc');
                expect(performance1.score).toEqual(100);
              }
            );

            it(
              'fails validation if a non-numeric score is provided',
              () => {
                store.unsavedPerformance.score = 'abc';
                store.savePerformanceEdits();
                expectPerformanceValidationFailure(
                  'cellScore',
                  ['Points must be a number']
                );
                expect(performance1.description).toEqual('col_1_row_1_old_desc');
                expect(performance1.score).toEqual(100);
              }
            );

            it(
              'fails validation if a score of zero is provided',
              () => {
                store.unsavedPerformance.score = '0';
                store.savePerformanceEdits();
                expectPerformanceValidationFailure(
                  'cellScore',
                  ['Points must be greater than zero']
                );
                expect(performance1.description).toEqual('col_1_row_1_old_desc');
                expect(performance1.score).toEqual(100);
              }
            );

            it(
              'fails validation if a decimal score is specified',
              () => {
                store.unsavedPerformance.score = '1.1';
                store.savePerformanceEdits();
                expectPerformanceValidationFailure(
                  'cellScore',
                  ['Points must be a whole number']
                );
                expect(performance1.description).toEqual('col_1_row_1_old_desc');
                expect(performance1.score).toEqual(100);
              }
            );

            it(
              'passes validation if a decimal score ending in .0 is specified',
              () => {
                store.unsavedPerformance.score = '1.0';
                store.savePerformanceEdits();
                expect(store.validationError['cellScore']).toBeNull;
                expect(performance1.score).toEqual(1);
              }
            );
          }
        );
      }
    );

    describe(
      'startEditingCriterion',
      () => {
        let criterion1;

        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            criterion1 = store.content.criterias[0].Criteria;
            store.startEditingCriterion(criterion1);
          }
        );

        it(
          'sets the criterionToEdit property to the specified criterion',
          () => {
            expect(store.criterionToEdit).toEqual(criterion1);
          }
        );

        it(
          'initializes unsavedCriterion to a copy of the specified criterion',
          () => {
            expect(store.unsavedCriterion.title).toEqual(criterion1.title);
            // Make a change to the unsavedCriterion and verify it doesn't
            // change the original.
            store.unsavedCriterion.title = 'new_title';

            expect(criterion1.title).not.toEqual(store.unsavedCriterion.title);
          }
        );
      }
    );

    describe(
      'startEditingHeader',
      () => {
        let header1;

        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            header1 = store.content.header_row.HeaderRow.header_columns[0];
            store.startEditingHeader(header1);
          }
        );

        it(
          'sets the headerToEdit property to the specified header',
          () => {
            expect(store.headerToEdit).toEqual(header1);
          }
        );

        it(
          'initializes unsavedHeader to a copy of the specified header',
          () => {
            expect(store.unsavedHeader.label).toEqual(header1.label);
            // Make a change to the unsavedHeader and verify it doesn't
            // change the original.
            store.unsavedHeader.label = 'new_label';

            expect(header1.label).not.toEqual(store.unsavedHeader.label);
          }
        );
      }
    );

    describe(
      'startEditingPerformance',
      () => {
        let performance1;

        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            performance1 = store.content.criterias[0].Criteria.performances[0];
            store.startEditingPerformance(performance1);
          }
        );

        it(
          'sets the performanceToEdit property to the specified performance',
          () => {
            expect(store.performanceToEdit).toEqual(performance1);
          }
        );

        it(
          'initializes unsavedPerformance to a copy of the specified performance',
          () => {
            expect(store.unsavedPerformance.description).toEqual(performance1.description);
            // Make a change to the unsavedPerformance and verify it doesn't
            // change the original.
            store.unsavedPerformance.description = 'new_description';

            expect(performance1.description).not.toEqual(store.unsavedPerformance.description);
          }
        );
      }
    );
    describe(
      'addNewColumn',
      () => {
        let headersCount;
        let lastAddedColumn;
        let expectedNewColumnStore;
        let indexSelected;
        let selectedHeaderColumn;

        beforeEach(
          () => {
            expectedNewColumnStore = {
              show_score: true,
              header_row: {
                HeaderRow: {
                  header_columns: [
                    { id: '1', label: 'old_header_1_label' },
                    { id: '3', label: 'New column 1' },
                    { id: '2', label: 'old_header_2_label' },
                  ],
                },
              },
              criterias: [
                {
                  Criteria: {
                    title: 'old_title_1',
                    performances: [
                      {
                        header_id: '1',
                        description: 'col_1_row_1_old_desc',
                        score: 100,
                      },
                      {
                        header_id: '3',
                        description: 'Edit description and points',
                        score: 1,
                      },
                      {
                        header_id: '2',
                        description: 'col_2_row_1_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
                {
                  Criteria: {
                    title: 'old_title_2',
                    performances: [
                      {
                        header_id: '1',
                        description: 'col_1_row_2_old_desc',
                        score: 100,
                      },
                      {
                        header_id: '3',
                        description: 'Edit description and points',
                        score: 1,
                      },
                      {
                        header_id: '2',
                        description: 'col_2_row_2_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
              ],
            };
          }
        );

        describe(
          'add a new column on the left of currentColumn',
          () => {
            beforeEach(
              () => {
                indexSelected = 1;
                headersCount = expectedNewColumnStore.header_row.HeaderRow.header_columns.length;
                store.init({ rubricJson: initialRubricJson });
                lastAddedColumn = store.lastAddedColumnNumber;
                selectedHeaderColumn = store.headerColumns[indexSelected];

                store.addNewColumn(indexSelected);
              }
            );
            it(
              'adds a new header column',
              () => {
                expect(store.headerColumns[indexSelected])
                  .toEqual(expectedNewColumnStore.header_row.HeaderRow.header_columns[indexSelected]);
              }
            );
            it(
              'adds a new performances column',
              () => {
                expect(store.criterias)
                  .toEqual(expectedNewColumnStore.criterias);
              }
            );
            it(
              'shift the selected column one index to the right',
              () => {
                expect(store.headerColumns[indexSelected + 1])
                  .toEqual(selectedHeaderColumn);
              }
            );
            it(
              'adds a new indexed header according to the maximum number of headers',
              () => {
                expect(store.headerColumns.length)
                  .toEqual(headersCount);
              }
            );

            it(
              'save last added colummn number',
              () => {
                expect(store.lastAddedColumnNumber).toEqual(lastAddedColumn + 1);
              }
            );

            it(
              'sets an assistive message that a column was added',
              () => {
                expect(store.state.message).toEqual('A new column was added');
              }
            );

            it(
              'shows the column containing the assistive message',
              () => {
                expect(store.state.assistiveColumn).toBe(true);
              }
            );
          }
        );

        describe(
          'add a new column on the right of currentColumn',
          () => {
            indexSelected;
            beforeEach(
              () => {
                indexSelected = 0;

                headersCount = expectedNewColumnStore.header_row.HeaderRow.header_columns.length;
                store.init({ rubricJson: initialRubricJson });
                lastAddedColumn = store.lastAddedColumnNumber;

                selectedHeaderColumn = store.content.header_row
                  .HeaderRow.header_columns[indexSelected];
                store.addNewColumn(indexSelected + 1);
              }
            );
            it(
              'adds a new header column at right of currentColumn',
              () => {
                expect(store.headerColumns[indexSelected + 1])
                  .toEqual(expectedNewColumnStore.header_row.HeaderRow.header_columns[indexSelected + 1]);
              }
            );
            it(
              'adds a new performances column',
              () => {
                expect(store.criterias).toEqual(expectedNewColumnStore.criterias);
              }
            );
            it(
              'keep selected column in the same index',
              () => {
                expect(store.headerColumns[indexSelected])
                  .toEqual(selectedHeaderColumn);
              }
            );
            it(
              'adds a new indexed header according to the maximum number of headers',
              () => {
                expect(store.content.header_row.HeaderRow.header_columns.length)
                  .toEqual(headersCount);
              }
            );

            it(
              'save last added colummn number',
              () => {
                expect(store.lastAddedColumnNumber).toEqual(lastAddedColumn + 1);
              }
            );

            it(
              'set assistive message',
              () => {
                expect(store.state.message).toEqual('A new column was added');
              }
            );

            it(
              'show assistive message',
              () => {
                expect(store.state.assistiveColumn).toBe(true);
              }
            );
          }
        );

        describe(
          'when there are already the maximum number of allowed columns',
          () => {
            beforeEach(
              () => {
                indexSelected = 1;
                store.init({ rubricJson: initialRubricJson });

                store.addNewColumn(indexSelected);
                store.addNewColumn(indexSelected);
                store.addNewColumn(indexSelected);

                lastAddedColumn = store.lastAddedColumnNumber;
                store.addNewColumn(indexSelected);
              }
            );

            it(
              'does not add one more header column',
              () => {
                expect(store.headerColumns.length)
                  .toEqual(store.maxColumns);
              }
            );

            it(
              'does not save last added colummn number',
              () => {
                expect(store.lastAddedColumnNumber).toEqual(lastAddedColumn);
              }
            );
          }
        );

        describe(
          'when add the last column allowed hides banner alert for recovering last column deleted',
          () => {
            beforeEach(
              () => {
                indexSelected = 1;
                store.init({ rubricJson: initialRubricJson });


                store.deleteColumn(indexSelected);
                store.addNewColumn(indexSelected);
                store.addNewColumn(indexSelected);
                store.addNewColumn(indexSelected);
              }
            );

            it(
              'does not modify showBannerAlert',
              () => {
                expect(store.showBannerAlert).toEqual(true);
              }
            );

            it(
              'does not show banner alert',
              () => {
                store.addNewColumn(indexSelected);
                expect(store.showBannerAlert).toEqual(false);
              }
            );

            it(
              'clear ',
              () => {
                store.addNewColumn(indexSelected);
                expect(store.lastDataDeleted).toEqual({});
              }
            );
          }
        );
      }
    );
    describe(
      'addNewRow',
      () => {
        let lastAddedRowNumber;
        let indexSelected;
        let expectedNewRowStore;
        let selectedCriteriaRow;

        beforeEach(
          () => {
            expectedNewRowStore = {
              show_score: true,
              header_row: {
                HeaderRow: {
                  header_columns: [
                    { id: '1', label: 'old_header_1_label' },
                    { id: '2', label: 'old_header_2_label' },
                  ],
                },
              },
              criterias: [
                {
                  Criteria: {
                    title: 'old_title_1',
                    performances: [
                      {
                        header_id: '1',
                        description: 'col_1_row_1_old_desc',
                        score: 100,
                      },
                      {
                        header_id: '2',
                        description: 'col_2_row_1_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
                {
                  Criteria: {
                    title: 'New row 1',
                    performances: [
                      {
                        header_id: '1',
                        description: 'Edit description and points',
                        score: 1,
                      },
                      {
                        header_id: '2',
                        description: 'Edit description and points',
                        score: 1,
                      },
                    ],
                  },
                },
                {
                  Criteria: {
                    title: 'old_title_2',
                    performances: [
                      {
                        header_id: '1',
                        description: 'col_1_row_2_old_desc',
                        score: 100,
                      },
                      {
                        header_id: '2',
                        description: 'col_2_row_2_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
              ],
            };
          }
        );

        describe(
          'adding a new row above the specified row',
          () => {
            beforeEach(
              () => {
                indexSelected = 1;
                store.init({ rubricJson: initialRubricJson });
                lastAddedRowNumber = store.lastAddedRowNumber;
                selectedCriteriaRow = store.criterias[indexSelected];
                store.addNewRow(indexSelected);
              }
            );

            it(
              'adds a new criterias object',
              () => {
                expect(store.criterias[indexSelected])
                  .toEqual(expectedNewRowStore.criterias[indexSelected]);
              }
            );

            it(
              'sets Criteria title as unique',
              () => {
                expect(store.criterias[indexSelected].Criteria.title)
                  .toEqual('New row 1');
              }
            );

            it(
              'it moves the specified row down',
              () => {
                expect(store.criterias[indexSelected + 1])
                  .toEqual(selectedCriteriaRow);
              }
            );

            it(
              'save last added row number',
              () => {
                expect(store.lastAddedRowNumber).toEqual(2);
              }
            );

            it(
              'sets an assistive message that a row was added',
              () => {
                expect(store.state.message).toEqual('A new row was added');
              }
            );

            it(
              'shows the row containing the assistive message',
              () => {
                expect(store.state.assistiveRow).toBe(true);
              }
            );
          }
        );

        describe(
          'adding a new row below the specified row',
          () => {
            beforeEach(
              () => {
                indexSelected = 0;
                store.init({ rubricJson: initialRubricJson });
                lastAddedRowNumber = store.lastAddedRowNumber;
                selectedCriteriaRow = store.criterias[indexSelected];
                store.addNewRow(indexSelected + 1);
              }
            );

            it(
              'adds a new criterias object',
              () => {
                expect(store.criterias[indexSelected + 1])
                  .toEqual(expectedNewRowStore.criterias[indexSelected + 1]);
              }
            );

            it(
              'sets Criteria title as unique',
              () => {
                expect(store.criterias[indexSelected + 1].Criteria.title)
                  .toEqual(`New row ${store.lastAddedRowNumber - 1}`);
              }
            );

            it(
              'does not change the position of the specified row',
              () => {
                expect(store.criterias[indexSelected])
                  .toEqual(selectedCriteriaRow);
              }
            );

            it(
              'save last added row number',
              () => {
                expect(store.lastAddedRowNumber).toEqual(lastAddedRowNumber + 1);
              }
            );

            it(
              'sets an assistive message that a row was added',
              () => {
                expect(store.state.message).toEqual('A new row was added');
              }
            );

            it(
              'shows the row containing the assistive message',
              () => {
                expect(store.state.assistiveRow).toBe(true);
              }
            );
          }
        );

        describe(
          'when there are already the maximum number of allowed rows',
          () => {
            beforeEach(
              () => {
                store.init({ rubricJson: initialRubricJson });

                const countMaxRows = store.maxRows - store.headerColumns.length;

                for (let i = 0; i < countMaxRows + 1; i++ ) {
                  store.addNewRow();
                }
              }
            );

            it(
              'does not add one more criterias row',
              () => {
                expect(store.criterias.length)
                  .toEqual(store.maxRows);
              }
            );
          }
        );

        describe(
          'when add the last column allowed hides banner alert for recovering last row deleted',
          () => {
            beforeEach(
              () => {
                indexSelected = 0;
                store.init({ rubricJson: initialRubricJson });

                const countMaxRows = store.maxRows - store.headerColumns.length;


                store.deleteRow(indexSelected);
                for (let i = 0; i < countMaxRows; i++ ) {
                  store.addNewRow(indexSelected);
                }
              }
            );

            it(
              'does not modify showBannerAlert',
              () => {
                expect(store.showBannerAlert).toEqual(true);
              }
            );

            it(
              'does not show banner alert',
              () => {
                store.addNewRow(indexSelected);
                expect(store.showBannerAlert).toEqual(false);
              }
            );

            it(
              'clear ',
              () => {
                store.addNewRow(indexSelected);
                expect(store.lastDataDeleted).toEqual({});
              }
            );
          }
        );

        describe(
          'when there is a new row created before',
          () => {
            let initialRubricObjectNewRow;
            beforeEach(
              () => {
                initialRubricObjectNewRow = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '1', label: 'old_header_1_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'New row 1',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                store.init({ rubricJson: JSON.stringify(initialRubricObjectNewRow) });
                store.addNewRow(0);
              }
            );

            it(
              'adds new row 2',
              () => {
                expect(store.criterias[0].Criteria.title)
                  .toContain('2');
              }
            );
            it(
              'adds new row 3',
              () => {
                store.addNewRow(0);
                expect(store.criterias[0].Criteria.title)
                  .toContain('3');
              }
            );
          }
        );
      }
    );
    describe(
      'deleteRow',
      () => {
        let deleteRowObject;
        let lastRowDeleted;

        beforeEach(
          () => {
            deleteRowObject = {
              show_score: true,
              header_row: {
                HeaderRow: {
                  header_columns: [
                    { id: '1', label: 'old_header_1_label' },
                    { id: '2', label: 'old_header_2_label' },
                  ],
                },
              },
              criterias: [
                {
                  Criteria: {
                    title: 'old_title_2',
                    performances: [
                      {
                        header_id: '1',
                        description: 'col_1_row_2_old_desc',
                        score: 100,
                      },
                      {
                        header_id: '2',
                        description: 'col_2_row_2_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
              ],
            };

            lastRowDeleted = {
              performances: [
                {
                  Criteria: {
                    title: 'old_title_1',
                    performances: [
                      {
                        header_id: '1',
                        description: 'col_1_row_1_old_desc',
                        score: 100,
                      },
                      {
                        header_id: '2',
                        description: 'col_2_row_1_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
                {
                  Criteria: {
                    title: 'old_title_2',
                    performances: [
                      {
                        header_id: '1',
                        description: 'col_1_row_2_old_desc',
                        score: 100,
                      },
                      {
                        header_id: '2',
                        description: 'col_2_row_2_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
              ],
            };

            store.init({ rubricJson: initialRubricJson });
            store.deleteRow(store.content, 0);
          }
        );

        it(
          'removes first criteria',
          () => {
            expect(store.content)
              .toEqual(deleteRowObject);
          }
        );

        it(
          'sets an assistive message that a row was deleted',
          () => {
            expect(store.state.message).toEqual('Row delete');
          }
        );

        it(
          'shows the row with the assistive message',
          () => {
            expect(store.state.assistiveRow).toBe(true);
          }
        );

        it(
          'does not delete the row there is only one left',
          () => {
            store.deleteRow(0);
            store.deleteRow(0);
            expect(store.criterias.length)
              .toEqual(1);
          }
        );

        it(
          'shows undo alert banner',
          () => {
            expect(store.showBannerAlert).toBe(true);
          }
        );

        it(
          'saves removed criteria data',
          () => {
            store.deleteRow(0);
            expect(store.lastDataDeleted)
              .toEqual(lastRowDeleted);
          }
        );
      }
    );
    describe(
      'deleteColumn',
      () => {
        let deleteColumnObject;
        let lastColumnDeleted;

        beforeEach(
          () => {
            deleteColumnObject = {
              show_score: true,
              header_row: {
                HeaderRow: {
                  header_columns: [
                    { id: '2', label: 'old_header_2_label' },
                  ],
                },
              },
              criterias: [
                {
                  Criteria: {
                    title: 'old_title_1',
                    performances: [
                      {
                        header_id: '2',
                        description: 'col_2_row_1_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
                {
                  Criteria: {
                    title: 'old_title_2',
                    performances: [
                      {
                        header_id: '2',
                        description: 'col_2_row_2_old_desc',
                        score: 100,
                      },
                    ],
                  },
                },
              ],
            };

            lastColumnDeleted = {
              headerId: 0,
              lastHeaderRemoved: { id: '1', label: 'old_header_1_label' },
              performances: [
                { header_id: '1', description: 'col_1_row_1_old_desc', score: 100 },
                { header_id: '1', description: 'col_1_row_2_old_desc', score: 100 },
              ],
            };
            store.init({ rubricJson: initialRubricJson });
            store.deleteColumn(0);
          }
        );

        it(
          'deletes the column specified by the index argument',
          () => {
            expect(store.content)
              .toEqual(deleteColumnObject);
          }
        );

        it(
          'sets an assistive message that a column was deleted',
          () => {
            expect(store.state.message).toEqual('Column delete');
          }
        );

        it(
          'shows the column with the assistive message',
          () => {
            expect(store.state.assistiveColumn).toBe(true);
          }
        );

        it(
          'does not delete the column there is only one left',
          () => {
            store.deleteColumn(0);
            store.deleteColumn(0);
            store.deleteColumn(0);
            expect(store.headerColumns.length)
              .toEqual(1);
          }
        );

        it(
          'shows undo alert banner',
          () => {
            expect(store.showBannerAlert).toBe(true);
          }
        );

        it(
          'saves deleted the column header id specified by the index argument',
          () => {
            expect(store.lastDataDeleted.headerId)
              .toEqual(lastColumnDeleted.headerId);
          }
        );

        it(
          'saves deleted the column header data specified by the index argument',
          () => {
            expect(store.lastDataDeleted.lastHeaderRemoved)
              .toEqual(lastColumnDeleted.lastHeaderRemoved);
          }
        );

        it(
          'saves removed criteria data',
          () => {
            expect(store.lastDataDeleted)
              .toEqual(lastColumnDeleted);
          }
        );
      }
    );
    describe(
      'startEditingLine',
      () => {
        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
            store.startEditingLine(store.headerColumns[0]);
          }
        );

        it(
          'sets current line to edit',
          () => {
            expect(store.state.currentlyEditingLine)
              .toEqual(store.headerColumns[0]);
          }
        );

        it(
          'reasign currentlyEditingLine',
          () => {
            store.startEditingLine(store.headerColumns[1]);
            expect(store.state.currentlyEditingLine)
              .toEqual(store.headerColumns[1]);
          }
        );
      }
    );
    describe(
      'stopEditingLine',
      () => {
        let state;
        beforeEach(
          () => {
            state = {
              assistiveColumn: false,
              assistiveRow: false,
              currentlyEditingLine: null,
              message: '',
            };
            store.init({ rubricJson: initialRubricJson });
            store.startEditingLine(store.headerColumns[0]);
            store.stopEditingLine();
          }
        );

        it(
          'clean state values',
          () => {
            expect(store.state)
              .toEqual(state);
          }
        );
      }
    );
    describe(
      'canRemoveRows',
      () => {
        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
          }
        );

        it(
          'is true if there is more than one row',
          () => {
            expect(store.canRemoveRows)
              .toBe(true);
          }
        );

        it(
          'is false if there is only one row',
          () => {
            store.deleteRow(0);
            expect(store.canRemoveRows)
              .toBe(false);
          }
        );
      }
    );
    describe(
      'canRemoveColumns',
      () => {
        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
          }
        );

        it(
          'is true if there is more than one column',
          () => {
            expect(store.canRemoveColumns)
              .toBe(true);
          }
        );

        it(
          'is false if there is only one column',
          () => {
            store.deleteColumn(0);
            expect(store.canRemoveColumns)
              .toBe(false);
          }
        );
      }
    );
    describe(
      'undoLastRemovedData',
      () => {
        beforeEach(
          () => {
            store.init({ rubricJson: initialRubricJson });
          }
        );

        it(
          'Clears state with last deleted data',
          () => {
            store.undoLastRemovedData();
            expect(store.lastDataDeleted)
              .toEqual({});
          }
        );

        it(
          'Hides undo banner alert',
          () => {
            store.undoLastRemovedData();
            expect(store.showBannerAlert)
              .toEqual(false);
          }
        );

        describe(
          'undoColumn',
          () => {
            beforeEach(
              () => {
                store.deleteColumn(0);
                store.undoLastRemovedData();
              }
            );

            it(
              'Checks if undo column header was done correctly',
              () => {
                expect(store.headerColumns[0])
                  .toEqual(initialRubricObject.header_row.HeaderRow.header_columns[0]);
              }
            );

            it(
              'Checks if undo column criteria was done correctly',
              () => {
                expect(store.criterias[0].Criteria)
                  .toEqual(initialRubricObject.criterias[0].Criteria);
              }
            );

            it(
              'Sets message for deleted column',
              () => {
                expect(store.state.message).toEqual('A column was recovered');
              }
            );
          }
        );

        describe(
          'undoRow',
          () => {
            beforeEach(
              () => {
                store.deleteRow(0);
                store.undoLastRemovedData();
              }
            );

            it(
              'Checks if undo row criteria was done correctly',
              () => {
                expect(store.content.criterias).toEqual(initialRubricObject.criterias);
              }
            );

            it(
              'Sets message for deleted row',
              () => {
                expect(store.state.message).toEqual('A row was recovered');
              }
            );
          }
        );
      }
    );
    describe(
      'Drag and drop events',
      () => {
        let initialRubricObjectDnD;
        let initialRubricJsonDnD;
        beforeEach(() => {
          initialRubricObjectDnD = {
            show_score: true,
            header_row: {
              HeaderRow: {
                header_columns: [
                  { id: '1', label: 'old_header_1_label' },
                  { id: '2', label: 'old_header_2_label' },
                  { id: '3', label: 'old_header_3_label' },
                ],
              },
            },
            criterias: [
              {
                Criteria: {
                  title: 'old_title_1',
                  performances: [
                    {
                      header_id: '1',
                      description: 'col_1_row_1_old_desc',
                      score: 100,
                    },
                    {
                      header_id: '2',
                      description: 'col_2_row_1_old_desc',
                      score: 100,
                    },
                    {
                      header_id: '3',
                      description: 'col_3_row_1_old_desc',
                      score: 100,
                    },
                  ],
                },
              },
              {
                Criteria: {
                  title: 'old_title_2',
                  performances: [
                    {
                      header_id: '1',
                      description: 'col_1_row_2_old_desc',
                      score: 100,
                    },
                    {
                      header_id: '2',
                      description: 'col_2_row_2_old_desc',
                      score: 100,
                    },
                    {
                      header_id: '3',
                      description: 'col_3_row_2_old_desc',
                      score: 100,
                    },
                  ],
                },
              },
              {
                Criteria: {
                  title: 'old_title_3',
                  performances: [
                    {
                      header_id: '1',
                      description: 'col_1_row_3_old_desc',
                      score: 100,
                    },
                    {
                      header_id: '2',
                      description: 'col_2_row_3_old_desc',
                      score: 100,
                    },
                    {
                      header_id: '3',
                      description: 'col_3_row_3_old_desc',
                      score: 100,
                    },
                  ],
                },
              },
            ],
          };

          initialRubricJsonDnD = JSON.stringify(initialRubricObjectDnD);
        });
        describe(
          'handleDragStart',
          () => {
            let selectedData;
            const fixture = fs.readFileSync(
              path.resolve(__dirname, 'table_fixture.html'),
              { encoding: 'utf-8' }
            );
            let event;
            beforeEach(() => {
              document.body.innerHTML = fixture;
              event = new Event('dragstart');
              store.init({ rubricJson: initialRubricJsonDnD });
            }
            );

            it(
              'stores data to create a ghost column when drag a column header',
              () => {
                document.querySelector('#draggable-col-1').dispatchEvent(event);
                event.dataTransfer = {
                  effectAllowed: '',
                  setData: function(a, b) { },
                };
                selectedData = {
                  header: { id: '1', label: 'old_header_1_label' },
                  performances: [
                    {
                      header_id: '1',
                      description: 'col_1_row_1_old_desc',
                      score: 100,
                    }, {
                      header_id: '1',
                      description: 'col_1_row_2_old_desc',
                      score: 100,
                    },
                    {
                      header_id: '1',
                      description: 'col_1_row_3_old_desc',
                      score: 100,
                    },
                  ],
                  event: event,
                  type: 'col',
                };
                store.dragStartEvent(event);
                expect(store.selectedCellData)
                  .toEqual(selectedData);
              }
            );

            it(
              'stores data to create a ghost row when dragging a row header',
              () => {
                document.querySelector('#draggable-row-1').dispatchEvent(event);
                event.dataTransfer = {
                  effectAllowed: '',
                  setData: function(a, b) { },
                };
                selectedData = {
                  criteria: {
                    Criteria: {
                      title: 'old_title_1',
                      performances: [
                        {
                          header_id: '1',
                          description: 'col_1_row_1_old_desc',
                          score: 100,
                        },
                        {
                          header_id: '2',
                          description: 'col_2_row_1_old_desc',
                          score: 100,
                        },
                        {
                          header_id: '3',
                          description: 'col_3_row_1_old_desc',
                          score: 100,
                        },
                      ],
                    },
                  },
                  event: event,
                  type: 'row',
                };
                store.dragStartEvent(event);
                expect(store.selectedCellData)
                  .toEqual(selectedData);
              }
            );
          }
        );
        describe(
          'clearDragState',
          () => {
            let selectedData;
            beforeEach(
              () => {
                selectedData = {
                  criteria: {},
                  header: {},
                  performances: [],
                  event: {},
                  type: '',
                };
                store.init({ rubricJson: initialRubricJson });
                store.clearDragState();
              }
            );

            it(
              'cleans up selectedCellData',
              () => {
                expect(store.selectedCellData)
                  .toEqual(selectedData);
              }
            );
          }
        );
        describe(
          'targetContainer',
          () => {
            const fixture = fs.readFileSync(
              path.resolve(__dirname, 'table_fixture.html'),
              { encoding: 'utf-8' }
            );
            let target;
            beforeEach(
              () => {
                document.body.innerHTML = fixture;

                store.init({ rubricJson: initialRubricJsonDnD });
                target = store.targetContainer(
                  document.querySelector('#gutter-child-col-1'), 'droppable');
              }
            );

            it(
              'gets droppable target',
              () => {
                expect(target)
                  .toEqual(document.querySelector('#gutter-col-1'));
              }
            );
          }
        );
        describe(
          'dragOverEventCol',
          () => {
            const fixture = fs.readFileSync(
              path.resolve(__dirname, 'table_fixture.html'),
              { encoding: 'utf-8' }
            );
            let eventDragOver;

            beforeEach(() => {
              document.body.innerHTML = fixture;

              eventDragOver = new Event('dragover');
              eventDragOver.dataTransfer = {
                dropEffect: '',
              };
              store.init({ rubricJson: initialRubricJsonDnD });
            });

            it(
              'returns null when selectedData type is row and event happen in a col',
              () => {
                document.querySelector('#draggable-col-1').dispatchEvent(eventDragOver);
                store.selectedCellData.type = 'row';
                store.dragOverEventCol(eventDragOver, 0);
                expect(store.currentColumnSelected).toBeNull();
              }
            );

            it(
              'sets column 1 as selected when event is on the left',
              () => {
                document.querySelector('#draggable-col-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-col-1').getBoundingClientRect = jest.fn(() => ({
                  width: 8,
                  left: 800,
                }));
                eventDragOver.clientX = 802;
                store.selectedCellData.type = 'col';
                store.dragOverEventCol(eventDragOver, '0');
                expect(store.currentColumnSelected)
                  .toEqual('0');
              }
            );

            it(
              'sets currentColumnSelectedPos as right when event is on the right',
              () => {
                document.querySelector('#draggable-col-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-col-1').getBoundingClientRect = jest.fn(() => ({
                  width: 8,
                  left: 800,
                }));
                eventDragOver.clientX = 805;
                store.selectedCellData.type = 'col';
                store.dragOverEventCol(eventDragOver, 0);
                expect(store.currentColumnSelectedPos)
                  .toEqual('right');
              }
            );

            it(
              'sets column 1 as selected when event is on the left',
              () => {
                document.querySelector('#draggable-col-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-col-1').getBoundingClientRect = jest.fn(() => ({
                  width: 8,
                  left: 800,
                }));
                eventDragOver.clientX = 805;
                store.selectedCellData.type = 'col';
                store.dragOverEventCol(eventDragOver, 0);
                expect(store.currentColumnSelected)
                  .toEqual('1');
              }
            );

            it(
              'sets currentColumnSelectedPos as left when event is on the left',
              () => {
                document.querySelector('#draggable-col-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-col-1').getBoundingClientRect = jest.fn(() => ({
                  width: 8,
                  left: 800,
                }));
                eventDragOver.clientX = 802;
                store.selectedCellData.type = 'col';
                store.dragOverEventCol(eventDragOver, 1);
                expect(store.currentColumnSelectedPos)
                  .toEqual('left');
              }
            );

            it(
              'sets currentAvailableTarget as col',
              () => {
                document.querySelector('#draggable-col-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-col-1').getBoundingClientRect = jest.fn(() => ({
                  width: 8,
                  left: 800,
                }));
                eventDragOver.clientX = 802;
                store.selectedCellData.type = 'col';
                store.dragOverEventCol(eventDragOver, 1);
                expect(store.currentAvailableTarget)
                  .toEqual('col');
              }
            );
          }
        );
        describe(
          'dragOverEventRow',
          () => {
            const fixture = fs.readFileSync(
              path.resolve(__dirname, 'table_fixture.html'),
              { encoding: 'utf-8' }
            );
            let eventDragOver;

            beforeEach(() => {
              document.body.innerHTML = fixture;

              eventDragOver = new Event('dragover');
              eventDragOver.dataTransfer = {
                dropEffect: '',
              };
              store.init({ rubricJson: initialRubricJsonDnD });
            });

            it(
              'returns null when selectedData type is col and event happen in a row',
              () => {
                document.querySelector('#draggable-row-1').dispatchEvent(eventDragOver);
                store.selectedCellData.type = 'col';
                store.dragOverEventRow(eventDragOver, 0);
                expect(store.currentRowSelected).toBeNull();
              }
            );

            it(
              'sets row 1 as selected when event is above',
              () => {
                document.querySelector('#draggable-row-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-row-1').getBoundingClientRect = jest.fn(() => ({
                  height: 10,
                  top: 400,
                }));
                eventDragOver.clientY = 402;
                store.selectedCellData.type = 'row';
                store.dragOverEventRow(eventDragOver, '0');
                expect(store.currentRowSelected)
                  .toEqual('0');
              }
            );

            it(
              'sets currentRowSelectedPos as above when event is above',
              () => {
                document.querySelector('#draggable-row-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-row-1').getBoundingClientRect = jest.fn(() => ({
                  height: 10,
                  top: 400,
                }));
                eventDragOver.clientY = 402;
                store.selectedCellData.type = 'row';
                store.dragOverEventRow(eventDragOver, '0');
                expect(store.currentRowSelectedPos)
                  .toEqual('above');
              }
            );

            it(
              'sets row 1 as selected when event is below',
              () => {
                document.querySelector('#draggable-row-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-row-1').getBoundingClientRect = jest.fn(() => ({
                  height: 10,
                  top: 400,
                }));
                eventDragOver.clientY = 407;
                store.selectedCellData.type = 'row';
                store.dragOverEventRow(eventDragOver, '0');
                expect(store.currentRowSelected)
                  .toEqual('1');
              }
            );

            it(
              'sets currentRowSelectedPos as below when event is below',
              () => {
                document.querySelector('#draggable-row-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-row-1').getBoundingClientRect = jest.fn(() => ({
                  height: 10,
                  top: 400,
                }));
                eventDragOver.clientY = 407;
                store.selectedCellData.type = 'row';
                store.dragOverEventRow(eventDragOver, 1);
                expect(store.currentRowSelectedPos)
                  .toEqual('below');
              }
            );

            it(
              'sets currentAvailableTarget as row',
              () => {
                document.querySelector('#draggable-row-1').dispatchEvent(eventDragOver);
                document.querySelector('#gutter-row-1').getBoundingClientRect = jest.fn(() => ({
                  height: 10,
                  top: 400,
                }));
                eventDragOver.clientY = 407;
                store.selectedCellData.type = 'row';
                store.dragOverEventRow(eventDragOver, 1);
                expect(store.currentAvailableTarget)
                  .toEqual('row');
              }
            );
          }
        );
        describe(
          'handleDrop',
          () => {
            const fixture = fs.readFileSync(
              path.resolve(__dirname, 'table_fixture.html'),
              { encoding: 'utf-8' }
            );
            let dragDropObject;
            let eventDrag;
            let eventDrop;

            beforeEach(() => {
              document.body.innerHTML = fixture;

              eventDrag = new Event('dragstart');
              eventDrag.dataTransfer = {
                effectAllowed: '',
                setData: function(a, b) { },
              };
              eventDrop = new Event('drop');
              store.init({ rubricJson: initialRubricJsonDnD });
            });

            it(
              'moves a col from right to left: from col 3 to col 1 by adding it on the left col 1',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '3', label: 'old_header_3_label' },
                        { id: '1', label: 'old_header_1_label' },
                        { id: '2', label: 'old_header_2_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-col-3').dispatchEvent(eventDrag);
                document.querySelector('#gutter-col-1').dispatchEvent(eventDrop);
                document.querySelector('#gutter-col-1').getBoundingClientRect = jest.fn(() => ({
                  width: 8,
                  left: 200,
                }));
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                eventDrop.clientX = 200;
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );

            it(
              'moves a col from right to left: from col 3 to col 2 adding it on the right of col 1',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '1', label: 'old_header_1_label' },
                        { id: '3', label: 'old_header_3_label' },
                        { id: '2', label: 'old_header_2_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-col-3').dispatchEvent(eventDrag);
                document.querySelector('#gutter-col-1').dispatchEvent(eventDrop);
                document.querySelector('#gutter-col-1').getBoundingClientRect = jest.fn(() => ({
                  width: 8,
                  left: 200,
                }));
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                eventDrop.clientX = 207;
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );

            it(
              'moves a col from left to right: from col 1 to col 3 by adding it on the left of col 3',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '2', label: 'old_header_2_label' },
                        { id: '1', label: 'old_header_1_label' },
                        { id: '3', label: 'old_header_3_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },

                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-col-1').dispatchEvent(eventDrag);
                document.querySelector('#gutter-col-3').dispatchEvent(eventDrop);
                document.querySelector('#gutter-col-3').getBoundingClientRect = jest.fn(() => ({
                  width: 8,
                  left: 800,
                }));
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                eventDrop.clientX = 801;
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );

            it(
              'moves a col from left to right: from col 1 to col 3 by adding it on the right of col 3',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '2', label: 'old_header_2_label' },
                        { id: '3', label: 'old_header_3_label' },
                        { id: '1', label: 'old_header_1_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-col-1').dispatchEvent(eventDrag);
                document.querySelector('#gutter-col-3').dispatchEvent(eventDrop);
                document.querySelector('#gutter-col-3').getBoundingClientRect = jest.fn(() => ({
                  width: 8,
                  left: 800,
                }));
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                eventDrop.clientX = 807;
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );

            it(
              'moves a col from right to left: from col 3 to col 1 by adding it on no actions col',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '3', label: 'old_header_3_label' },
                        { id: '1', label: 'old_header_1_label' },
                        { id: '2', label: 'old_header_2_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-col-3').dispatchEvent(eventDrag);
                document.querySelector('#gutter-no-actions-0').dispatchEvent(eventDrop);
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );

            it(
              'moves a row from below to above: from row 3 to row 1 by adding it above col 1',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '1', label: 'old_header_1_label' },
                        { id: '2', label: 'old_header_2_label' },
                        { id: '3', label: 'old_header_3_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-row-3').dispatchEvent(eventDrag);
                document.querySelector('#gutter-row-1').dispatchEvent(eventDrop);
                document.querySelector('#gutter-row-1').getBoundingClientRect = jest.fn(() => ({
                  height: 10,
                  top: 400,
                }));
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                eventDrop.clientY = 402;
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );

            it(
              'moves a row from below to above: from row 3 to row 2 adding it below of col 1',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '1', label: 'old_header_1_label' },
                        { id: '2', label: 'old_header_2_label' },
                        { id: '3', label: 'old_header_3_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-row-3').dispatchEvent(eventDrag);
                document.querySelector('#gutter-row-1').dispatchEvent(eventDrop);
                document.querySelector('#gutter-row-1').getBoundingClientRect = jest.fn(() => ({
                  height: 10,
                  top: 400,
                }));
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                eventDrop.clientY = 408;
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );

            it(
              'moves a row from above to below: from row 1 to row 3 by adding it below of col 3',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '1', label: 'old_header_1_label' },
                        { id: '2', label: 'old_header_2_label' },
                        { id: '3', label: 'old_header_3_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-row-1').dispatchEvent(eventDrag);
                document.querySelector('#gutter-row-3').dispatchEvent(eventDrop);
                document.querySelector('#gutter-row-3').getBoundingClientRect = jest.fn(() => ({
                  height: 10,
                  top: 800,
                }));
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                eventDrop.clientY = 808;
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );

            it(
              'moves a row from above to below: from row 1 to col 2 by adding it above of col 3',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '1', label: 'old_header_1_label' },
                        { id: '2', label: 'old_header_2_label' },
                        { id: '3', label: 'old_header_3_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-row-1').dispatchEvent(eventDrag);
                document.querySelector('#gutter-row-3').dispatchEvent(eventDrop);
                document.querySelector('#gutter-row-3').getBoundingClientRect = jest.fn(() => ({
                  height: 10,
                  top: 800,
                }));
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                eventDrop.clientY = 802;
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );

            it(
              'moves a row from above to below: from row 3 to col 1 by adding it on no actions row',
              () => {
                dragDropObject = {
                  show_score: true,
                  header_row: {
                    HeaderRow: {
                      header_columns: [
                        { id: '1', label: 'old_header_1_label' },
                        { id: '2', label: 'old_header_2_label' },
                        { id: '3', label: 'old_header_3_label' },
                      ],
                    },
                  },
                  criterias: [
                    {
                      Criteria: {
                        title: 'old_title_3',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_3_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_3_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_1',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_1_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_1_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                    {
                      Criteria: {
                        title: 'old_title_2',
                        performances: [
                          {
                            header_id: '1',
                            description: 'col_1_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '2',
                            description: 'col_2_row_2_old_desc',
                            score: 100,
                          },
                          {
                            header_id: '3',
                            description: 'col_3_row_2_old_desc',
                            score: 100,
                          },
                        ],
                      },
                    },
                  ],
                };
                document.querySelector('#draggable-row-3').dispatchEvent(eventDrag);
                document.querySelector('#gutter-no-actions-1').dispatchEvent(eventDrop);
                eventDrop.dataTransfer = {
                  getData: function(attr) {
                    return JSON.stringify(eventDrag.target.dataset);
                  },
                };
                store.dragStartEvent(eventDrag);
                store.handleDrop(eventDrop);
                expect(store.content)
                  .toEqual(dragDropObject);
              }
            );
          }
        );
      }
    );
  }
);
