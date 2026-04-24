import { defineStore } from 'pinia';

const useStudentDetailReportStore = defineStore('studentDetailReportStore', {
  state: () => ({
    selectedAssessmentIDs: '',
    selectedUnitId: '',
    selectedStandardId: '',
    selectedStandardSetRef: '',
  }),

  actions: {
    setSelectedAssessmentIDs(assessmentIDs) {
      this.selectedAssessmentIDs = assessmentIDs;
    },

    setSelectedUnitId(unitId) {
      this.selectedUnitId = unitId;
    },

    setSelectedStandardId(standardId) {
      this.selectedStandardId = standardId;
    },

    setSelectedStandardSetRef(standardSetRef) {
      this.selectedStandardSetRef = standardSetRef;
    },
  },
});

export default useStudentDetailReportStore;
