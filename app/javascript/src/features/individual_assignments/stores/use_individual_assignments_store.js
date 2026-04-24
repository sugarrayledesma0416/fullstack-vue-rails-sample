import { defineStore } from 'pinia';

const useIndividualAssignmentsStore = defineStore(
  'store',
  {
    state: () => {
      return {
        maxDueDate: '',
        minDueDate: '',
      };
    },
    getters: {
    },
    actions: {
      init({ minDueDate, maxDueDate }={}) {
        this.minDueDate = new Date(minDueDate);
        this.maxDueDate = new Date(maxDueDate);
      },
    },
  }
);

export default useIndividualAssignmentsStore;
