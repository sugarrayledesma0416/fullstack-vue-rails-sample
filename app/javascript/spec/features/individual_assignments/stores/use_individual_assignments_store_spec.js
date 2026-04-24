import { setActivePinia, createPinia } from 'pinia';
import useIndividualAssignmentsStore
  from 'features/individual_assignments/stores/use_individual_assignments_store';

describe(
  'useIndividualAssignmentsStore',
  () => {
    let store;
    let minDueDate;
    let maxDueDate;

    beforeEach(
      () => {
        setActivePinia(createPinia());
        store = useIndividualAssignmentsStore();
        minDueDate = '2023-02-02';
        maxDueDate = '2023-06-15';
      }
    );

    describe(
      'init',
      () => {
        it(
          'assigns the specified course start and end dates to the state',
          () => {
            store.init(
              {
                minDueDate,
                maxDueDate,
              }
            );

            expect(store.minDueDate).toEqual(new Date(minDueDate));
            expect(store.maxDueDate).toEqual(new Date(maxDueDate));
          }
        );
      }
    );
  }
);
