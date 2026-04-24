<template>
  <div
    class="filter-section"
    :class="{'u-dis-none': !props.showFilters.is_active}">
    <div class="u-mar-top-24">
      <div class="filter-text">
        Filter
      </div>
      <div class="line" />
    </div>
    <div
      class="u-mar-lt-24  u-mar-top-32">
      <div class="u-mar-top-16">
        <label for="standard_set_display_name" class="c-form-item__label">Standards</label>
        <BasicSelect
          id="standard_set_display_name"
          v-model="store.selectedStandardSetRef"
          name="standard_set_display_name"
          :class="testClass('standard-set-display-name')"
          :options="standardSetOptions"
          @change="resetSelects" />
      </div>

      <div class="u-mar-top-16">
        <label for="assessment_type" class="c-form-item__label">Assessment Type</label>
        <BasicSelect
          id="assessment_type"
          v-model="store.selectedAssessmentOption"
          name="assessment_type"
          :options="Object.entries(assessmentOptions).map(
            ([key, value]) => ({ value: key, text: value })
          )"
          :class="testClass('assessment-type')"
          @change="selectAssessmentType" />
      </div>

      <div class="u-mar-top-16">
        <label for="lesson_id" class="c-form-item__label">Unit</label>
        <BasicSelect
          id="lesson_id"
          ref="lessonSelect"
          v-model="store.selectedLessonId"
          name="lesson_id"
          :options="lessonOptions"
          :class="testClass('lesson-id')"
          @change="requestUnitDependentData" />
      </div>
      <div
        v-show="store.selectedAssessmentOption === 'proficiency'"
        class="filter-spacing">
        <label class="c-form-item__label">Assessments</label>
        <AssessmentMultipleSelect
          id="assessment_ids_select"
          ref="assessmentSelect"
          :assessments="assessments"
          :previouslySelectedActivityIdStrings="previouslySelectedActivityIds"
          @toggleAssessment="toggleAssessment" />
      </div>
      <div
        v-show="store.selectedAssessmentOption === 'progress_monitoring'"
        class="filter-spacing">
        <label class="c-form-item__label">Category Type</label>
        <CategoryMultipleSelect
          id="category_type_select"
          ref="categoryTypeSelect"
          :categories="store.selectedCategories" />
      </div>
      <input type="hidden" name="assessment_ids" :value="store.selectedAssessmentIdsString">
      <div class="c-button-group  c-button-group--lt  filter-spacing-go-btn">
        <input
          id="section_report_submit"
          type="button"
          name="commit"
          value="Go"
          class="c-button  filter-apply-btn  u-width-full"
          :class="testClass('filter-apply-btn')"
          data-disable-with="Go"
          :disabled="isGoBtnDisabled"
          @click="submitFilter()">
      </div>
    </div>
  </div>
  <!-- eslint-disable vue/no-multiple-template-root -->
  <div :class="[{'u-dis-none': props.showFilters.is_active}]">
    <button
      type="button"
      class="c-no-button  return-link"
      @click="submitFilter()">
      <music-icon-return
        class="c-embedded-icon  c-embedded-icon--return  c-embedded-icon--md"
        label="return"
        size="md"
        rotate="0" />
      <span class="c-embedded-icon__label">Return</span>
    </button>
  </div>
  <!-- eslint-enable vue/no-multiple-template-root -->
</template>

<script setup>
  import { computed, onMounted, reactive, ref } from 'vue';
  import AssessmentMultipleSelect from './AssessmentMultipleSelect';
  import CategoryMultipleSelect from './CategoryMultipleSelect';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.2/BasicSelect';
  import useSectionReportFilterStore from '../stores/use_section_report_filter_store';
  import { metaTagContent, postToEndpoint, testClass } from 'music';

  const props = defineProps({
    courseId: { type: Number, required: true },
    gradebookStandardsStudentsCsvPath: { required: true, type: String },
    lessons: { type: Array, default: () => [] },
    previouslySelectedActivityIdStrings: { type: Array, default: null },
    programId: { type: Number, required: true },
    sectionId: { type: Number, required: true },
    sectionReportPath: { type: String, required: true },
    selectedLesson: { type: String, default: '' },
    selectedStandardSet: { type: String, default: '' },
    showFilters: { type: Object, default: null },
    pmrStandardReportsAllowed: { type: String, required: true },
    standardSets: { type: Array, default: () => [] },
    standardsExportCsvBaseUrl: { type: String, required: true },
    validFilters: { type: Boolean, default: false },
  });

  const lessonSelect = ref(null);
  const assessmentSelect = ref(null);
  const categoryTypeSelect = ref(null);
  const assessments = ref([]);
  const store = useSectionReportFilterStore();
  const transientDataFetch = ref(false);
  const currentProgram = ref(metaTagContent('VHL.program_id') || null);
  const sectionReportFiltersData = ref(JSON.parse(
    sessionStorage.getItem('sectionReportFiltersData')
  ) || null);
  const storedUnitForProgram = ref(JSON.parse(
    sessionStorage.getItem('storedUnitForProgram')
  ) || null);
  const standardSetOptions = props.standardSets.map((standardSet) => {
    return {
      value: standardSet,
      text: standardSet,
    };
  });

  const lessonOptions = [
    { value: '', text: 'Select a Unit' },
    ...props.lessons.map((lessonData) => {
      return {
        value: lessonData[1],
        text: lessonData[0],
      };
    }),
  ];

  const assessmentOptions = {
    'proficiency': 'Proficiency',
    ...(props.pmrStandardReportsAllowed === 'true' && {
      'progress_monitoring': 'Progress Monitoring',
    }),
  };

  const previouslySelectedActivityIds = ref(props.previouslySelectedActivityIdStrings || []);

  const proficiencyAssessmentIds = computed(() => {
    return store.selectedAssessmentIdsString ||
      (
        sectionReportFiltersData.value &&
        sectionReportFiltersData.value[currentProgram.value]?.assessment_ids
      );
  });

  const getSectionReportFiltersData = computed(() => {
    return sectionReportFiltersData.value && sectionReportFiltersData.value[currentProgram.value];
  });

  const selectedCategories = computed(() => {
    return store.selectedCategories.filter(
      (category, index) => store.isCategoryChecked[index]
    ).join(', ');
  });

  const isEmptyFilterForPmr = computed(() => {
    return store.selectedAssessmentOption === 'progress_monitoring' &&
      Object.values(store.isCategoryChecked).every((value) => value === false);
  });

  const isEmptyFilterForProficiency = computed(() => {
    return store.selectedAssessmentOption === 'proficiency' &&
      store.selectedAssessmentIds?.size === 0;
  });

  const areCategoriesOrAssessmentsSame = computed(() => {
    if (store.selectedAssessmentOption === 'proficiency') {
      return store.appliedFilterState?.proficiencyAssessmentIds === proficiencyAssessmentIds.value;
    } else if (store.selectedAssessmentOption === 'progress_monitoring') {
      const appliedCategories = store.appliedFilterState?.selectedCategories || [];
      const currentCategories = store.selectedCategories.filter(
        (category, index) => store.isCategoryChecked[index]
      );
      return JSON.stringify(appliedCategories.sort()) === JSON.stringify(currentCategories.sort());
    }
    return false;
  });

  const isFilterStateChanged = computed(() => {
    return !(
      store.appliedFilterState?.selectedStandardSetRef === store.selectedStandardSetRef &&
      store.appliedFilterState?.assessmentType === store.selectedAssessmentOption &&
      store.appliedFilterState?.selectedLessonId === store.selectedLessonId &&
      areCategoriesOrAssessmentsSame.value
    );
  });

  /**
   * Go button is disabled when
   * - Any data fetch related to filter controls is in progress.
   * - If no assessment ids are selected for proficiency type.
   * - If no categories are selected for progress monitoring type.
   * - If filter control's selected values are same as the last applied filter state.
   */
  const isGoBtnDisabled = computed(() => {
    const disabled = isEmptyFilterForProficiency.value ||
      isEmptyFilterForPmr.value ||
      transientDataFetch.value ||
      !isFilterStateChanged.value;

    return disabled;
  });

  /**
   * Set the applied filter for future comparison.
   */
  function setAppliedFilters() {
    store.updateAppliedFilterState();
    store.setAppliedFilterState({
      proficiencyAssessmentIds: proficiencyAssessmentIds.value,
    });
  }

  const emit = defineEmits([
    'getSectionFilterData',
    'hideFiltersSection',
  ]);

  onMounted(() => {
    store.setSelectedStandardSetRef(props.standardSets[0]);
    if (getSectionReportFiltersData.value) {
      store.setSelectedAssessmentOption(
        sectionReportFiltersData.value[currentProgram.value].assessment_type
      );
    }
    store.setSelectedLessonId(lessonOptions[1]?.value);

    if (
      getSectionReportFiltersData.value &&
      sectionReportFiltersData.value[currentProgram.value].assessment_type === 'progress_monitoring'
    ) {
      requestCategories(
        { target: {
          value: parseInt(sectionReportFiltersData.value[currentProgram.value].lesson_id),
        }},
        true
      );
      store.setSelectedStandardSetRef(
        sectionReportFiltersData.value[currentProgram.value].standard_set_display_name
      );
    } else {
      if (storedUnitForProgram.value) {
        store.setSelectedLessonId(
          parseInt(storedUnitForProgram.value[currentProgram.value]?.selectedUnit)
        );
        requestAssessments({ target: { value: store.selectedLessonId }});
      } else if (
        getSectionReportFiltersData.value
      ) {
        store.setSelectedLessonId(
          parseInt(sectionReportFiltersData.value[currentProgram.value].lesson_id)
        );
        store.setSelectedStandardSetRef(
          sectionReportFiltersData.value[currentProgram.value].standard_set_display_name
        );
        requestAssessments({ target: { value: store.selectedLessonId }}, true);
      } else {
        store.setSelectedLessonId(lessonOptions[1].value);
        requestAssessments({ target: { value: store.selectedLessonId }});
      }
    }

    /**
     * The user has to select activities manually to submit the form,
     * even if requestAssessments automatically selects the previously selected
     * activities.
     */
    // submitButtonIsDisabled.value = true;
  });


  /**
   * Fetch assessments or categories for the new unit selection
   * @param {Event} event
   */
  function requestUnitDependentData(event) {
    if (store.selectedAssessmentOption === 'proficiency') {
      requestAssessments(event);
    } else if (store.selectedAssessmentOption === 'progress_monitoring') {
      requestCategories(event);
    }
  }

  /**
   * Requests categories based on the selected lesson and updates the store.
   *
   * @param {Event} event
   * @param {boolean} shouldSubmitFilter
   * @return {void}
   */
  function requestCategories(event, shouldSubmitFilter = false) {
    transientDataFetch.value = true;
    store.setSelectedLessonId(event.target.value);
    const url = `/gradebook/${props.programId}/courses/${props.courseId}/sections/` +
      `${props.sectionId}/standards/categories`;
    postToEndpoint(
      url,
      { selected_lesson_id: store.selectedLessonId },
      (response) => {
        store.resetCategoryCheck();
        store.setSelectedCategories(response.categories || []);
        store.setPmrAssessmentIds(response.assessment_ids || []);
        transientDataFetch.value = false;
        if (shouldSubmitFilter) {
          submitProgressMonitoringFilter(store.selectedCategories);
        }
      }
    );
  }

  /**
   * Requests and loads assessments for the selected lesson (unit).
   * It sends a request to retrieve assessments based on the selected lesson,
   * updates the assessment data, and optionally selects assessments by default.
   *
   * @param {Event} event - The event triggered when a lesson is selected.
   * @param {boolean} [selectedAssessmentIdsByDefault=false]
   */
  function requestAssessments(event, selectedAssessmentIdsByDefault = false) {
    transientDataFetch.value = true;
    store.setSelectedLessonId(event.target.value);
    const url = `/gradebook/${props.programId}/courses/${props.courseId}/sections/` +
      `${props.sectionId}/standards/assessments`;

    /**
     * Every time a unit (lesson) is selected the assessment dropdown is disabled
     * this is an indication for the user that we are loading new information
     */
    assessments.value = [];
    store.clearSelectedAssessmentIds();
    assessmentSelect.value.collapse();

    /**
     * If we are requesting a new unit (lesson) we need to clear the previous activities
     */
    if (store.selectedLessonId !== props.selectedLesson) {
      previouslySelectedActivityIds.value = [];
    }

    postToEndpoint(
      url,
      { selected_lesson_id: store.selectedLessonId },
      (response) => {
        assessments.value = response.assessments || [];
        if (assessments.value.length > 0) {
          if (selectedAssessmentIdsByDefault) {
            if (sectionReportFiltersData.value) {
              sectionReportFiltersData.value[currentProgram.value] = {
                assessment_ids: assessments.value.map((assessment) => assessment[1]).toString(),
              };
            } else {
              sectionReportFiltersData.value = { [currentProgram.value]: {
                assessment_ids: assessments.value.map((assessment) => assessment[1]).toString(),
              }};
            }

            setPreloadAssesments();
            submitFilter();
          } else {
            setPreloadAssesments();
          }
        }
        transientDataFetch.value = false;
      }
    );
  }

  /**
   * Toggles the selected assessment ID in the store based on event details.
   * @param {Object} eventDetails
   */
  function toggleAssessment(eventDetails) {
    store.toggleSelectAssessmentId(eventDetails);
  }

  /**
   * Resets the assessment selection by collapsing the assessment select dropdown.
   */
  function resetSelects() {
    assessmentSelect.value.collapse();
  }

  /**
   * Selects the appropriate assessment type based on the selected assessment option in the store.
   * If 'Progress Monitoring' is selected, it requests categories;
   * otherwise, it requests assessments.
   */
  function selectAssessmentType() {
    if (store.selectedAssessmentOption === 'progress_monitoring') {
      requestCategories({ target: { value: store.selectedLessonId }});
    } else {
      requestAssessments({ target: { value: store.selectedLessonId }});
    }
  }

  /**
   * Submits the appropriate filter based on the selected assessment option.
   * If the option is 'Proficiency', it submits a proficiency filter;
   * otherwise, it submits a progress monitoring filter.
   */
  function submitFilter() {
    setAppliedFilters();
    if (store.selectedAssessmentOption === 'proficiency') {
      submitProficiencyAssessmentFilter();
    } else {
      submitProgressMonitoringFilter();
    }
  }

  /**
   * Submits a proficiency assessment filter by gathering filter data,
   * constructing the request URL, and sending it to the backend endpoint.
   */
  function submitProficiencyAssessmentFilter() {
    const filtersData = {
      assessment_ids: proficiencyAssessmentIds.value,
      assessment_type: store.selectedAssessmentOption,
      lesson_id: store.selectedLessonId,
      standard_set_display_name: store.selectedStandardSetRef,
    };
    const url = `${props.sectionReportPath}&assessment_type=${store.selectedAssessmentOption}` +
      `&lesson_id=${ store.selectedLessonId }` +
      `&standard_set_display_name=${ store.selectedStandardSetRef }`;

    postToEndpoint(url, { assessment_ids: filtersData.assessment_ids }, (response) => {
      emit('getSectionFilterData', {
        assessments: response.assessments,
        filters_data: filtersData,
      });
      storedUnitForProgram.value?.splice(currentProgram.value, 1);
      sessionStorage.setItem('storedUnitForProgram', JSON.stringify(storedUnitForProgram.value));
      emit('hideFiltersSection', { is_active: true, standard_id: null });
    });
  }

  /**
   * Submits a progress monitoring filter by selecting necessary categories
   * and gathering filter data. Constructs the request URL and sends it to the backend.
   * @param {Array} categories
   */
  function submitProgressMonitoringFilter(categories = null) {
    const requiredCategories = categories ? categories.join(', ') : selectedCategories.value;
    const filtersData = {
      assessment_ids: store.pmrAssessmentIds.join(', '),
      assessment_type: store.selectedAssessmentOption,
      categories: requiredCategories,
      lesson_id: store.selectedLessonId,
      standard_set_display_name: store.selectedStandardSetRef,
    };

    const url = `${props.sectionReportPath}&assessment_type=${store.selectedAssessmentOption}` +
      `&lesson_id=${store.selectedLessonId}` +
      `&standard_set_display_name=${store.selectedStandardSetRef}`;
    postToEndpoint(
      url,
      { categories: filtersData.categories, assessment_ids: filtersData.assessment_ids },
      (response) => {
        emit('getSectionFilterData', {
          assessments: response.assessments,
          filters_data: filtersData,
        });
        emit('hideFiltersSection', { is_active: true, standard_id: null });
      }
    );
  }

  /**
   * Preloads assessments by setting previously selected activity IDs from the
   * section report filters. If assessments and filter data are available, it splits
   * the assessment IDs and marks that the user has changed the assessment selection.
   */
  function setPreloadAssesments() {
    if (assessments.value && sectionReportFiltersData.value) {
      previouslySelectedActivityIds.value =
        sectionReportFiltersData.value[currentProgram.value]?.assessment_ids?.split(',');
      store.userHasChangedAssessmentSelection = true;
    }
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .filter-spacing {
    margin-top: rpx(16);
    width: 90%;
  }

  .filter-spacing-go-btn {
    margin-top: rpx(24);
    width: 90%;
  }

  .filter-select-wrapper {
    padding-top: rpx(16);
  }

  ::v-deep .filter-select {
    background: #fff;
    background-position: center right rpx(6);
    background-size: rpx(16);
    height: rpx(48);
    max-width: 100%;
    padding: 0 rpx(24) 0 rpx(12);
    position: relative;
    transition: color 0.2s ease-in-out, border-color 0.2s;
    -webkit-transition: color 0.2s ease-in-out, border-color 0.2s ease-in-out;
  }

  ::v-deep .basic-select__dropdown {
    width: 90%;
    line-height: rpx(28);
  }

  ::v-deep .basic-select {
    width: 100%;
  }

  .line {
    background-color: #f44336;
    height: rpx(1);
  }

  .filter-text {
    font-size: rpx(16);
    font-weight: bold;
    margin: 0 0 rpx(8) rpx(46);
  }

  .filter-apply-btn {
    background: white;
    border: rpx(1) #ddd solid;
    color: #006BAE;
    margin-left: 0;
  }

  .filter-section {
    border-right: rpx(1) #e1dede solid;
    min-width: rpx(220);
    width: 20%;
  }

  .return-link {
    display: flex;
    margin: rpx(18) rpx(10) 0 rpx(32);
  }
</style>
