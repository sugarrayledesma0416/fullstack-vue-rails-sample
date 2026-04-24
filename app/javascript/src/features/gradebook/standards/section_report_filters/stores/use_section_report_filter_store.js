import { defineStore } from 'pinia';

const useSectionReportFilterStore = defineStore('store', {
  state: () => ({
    selectedAssessmentIds: new Set(),
    userHasChangedAssessmentSelection: false,
    selectedAssessmentOption: 'proficiency',
    selectedStandardSetRef: '',
    selectedLessonId: '',
    selectedCategories: [],
    isCategoryChecked: {},
    pmrAssessmentIds: [],
    appliedFilterState: {
      assessmentType: 'proficiency',
      proficiencyAssessmentIds: null,
      selectedCategories: [],
      selectedLessonId: '',
      selectedStandardSetRef: '',
      pmrAssessmentIds: [],
    },
  }),

  getters: {
    selectedAssessmentIdsString(state) {
      return [...state.selectedAssessmentIds].join(',');
    },
    isSelected: (state) => (assessmentId) => {
      return state.selectedAssessmentIds.has(assessmentId);
    },
    pmrAssessmentIdsString(state) {
      return state.pmrAssessmentIds.join(',');
    },
  },

  actions: {
    toggleSelectAssessmentId({ assessmentId, checked }) {
      if (checked) {
        this.selectedAssessmentIds.add(assessmentId);
      } else {
        this.selectedAssessmentIds.delete(assessmentId);
      }
      this.userHasChangedAssessmentSelection = true;
    },

    clearSelectedAssessmentIds() {
      this.selectedAssessmentIds.clear();
    },

    setSelectedAssessmentOption(option) {
      this.selectedAssessmentOption = option;
    },

    setSelectedStandardSetRef(value) {
      this.selectedStandardSetRef = value;
    },

    setSelectedLessonId(value) {
      this.selectedLessonId = value;
    },

    resetCategoryCheck() {
      this.isCategoryChecked = {};
    },

    setPmrAssessmentIds(ids) {
      this.pmrAssessmentIds = ids;
    },

    setSelectedCategories(categories) {
      this.selectedCategories = categories;
    },

    setAppliedFilterState(filterState) {
      this.appliedFilterState = { ...this.appliedFilterState, ...filterState };
    },

    updateAppliedFilterState() {
      this.appliedFilterState.selectedStandardSetRef = this.selectedStandardSetRef;
      this.appliedFilterState.assessmentType = this.selectedAssessmentOption;
      this.appliedFilterState.selectedLessonId = this.selectedLessonId;
      this.appliedFilterState.pmrAssessmentIds = [...this.pmrAssessmentIds];
      this.appliedFilterState.selectedCategories = this.selectedCategories.filter(
        (category, index) => this.isCategoryChecked[index]
      );
    },
  },
});

export default useSectionReportFilterStore;
