<template>
  <div>
    <ul class="l-line  chart-header">
      <li class="student-name">
        <select
          v-model="currentRosterStudent"
          class="c-select"
          :class="testClass('student-name')"
          @change="changeStudentRoster()">
          <option
            v-for="(student, studentKey) in rosterStudentListJSON"
            :key="studentKey"
            :value="student.id">
            {{ `${student.last_name}, ${student.first_name}` }}
          </option>
        </select>
      </li>
      <li class="cumulative-average">
        <div>
          <div class="u-txt-upper  u-txt-16  u-txt-gray-6">Cumulative avg grade</div>
          <div class="average">
            {{ Math.round(cumulative_average) }}%
          </div>
        </div>
      </li>
      <li class="l-line__splitter"></li>
    </ul>
    <GrowthAssessmentChart :config="config" @unitClicked="(unitData) => setStandardCategoryByUnit(unitData)" />
    <div
      v-if="standardCategoryStatus"
      class="standards-breakdown  l-container-fluid">
      <div class="standards-breakdown__header">
        <div class="standards-breakdown__header-item">
          <h2>{{ unitName.label }} Standards Breakdown</h2>
        </div>
        <div class="standards-breakdown__header-item">
          <label class="standard-set-dropdown-label">
            Standards
          </label>
          <select
            id="standard-set-select"
            v-model="standardSetRef"
            class="c-select  standard-set-dropdown"
            :class="[
              {'is-disabled': !standardCategoryStatus},
              testClass('standard-set-dropdown')]"
            :disabled="!standardCategoryStatus"
            @change="handleStandardSetDropdown()">
            <option
              v-for="(set, index) in availableSets"
              :key="`set-option-${index}`"
              :value="set.ids"
              :class="testClass(`set-option-${index}`)">
              {{ set.display_name }}
            </option>
          </select>
        </div>
      </div>
      <div class="standards-breakdown__container  l-line  l-line--wrap  l-line--justify">
        <div class="standards-breakdown__section">
          <StandardsCategoryList
            :standardCategoryList="standardCategory.list"
            :unitId="unit?.id"
            @getStandardsRange="getStandardsRange($event.unit_id, $event.lower, $event.upper)" />
        </div>
        <div class="standards-breakdown__section">
          <StandardsListByRange
            :selectedStandardGuid="props.selectedStandardGuid"
            :standardListByRange="standardListByRange.list"
            :tooltipInfo="tooltipInfo"
            @getStandardDetails="getStandardDetails($event)"
            @sortStandardList="sortStandardList($event.sort, $event.type)" />
        </div>
        <div class="standards-breakdown__section">
          <StandardsDetails
            :errorIconPath="errorIconPath"
            :reviewPath="reviewPath"
            :standardDetails="standardDetails.list"
            :standardsAssigningUrl="standardsAssigningUrl"
            :successIconPath="successIconPath"
            :summary="summary.list"
            :tooltipInfo="tooltipInfo"
            :unitId="unit.id" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { testClass, metaTagContent, } from 'music';
  import { computed, reactive, ref, onMounted } from 'vue';
  import * as ajaxUtils from 'shared/ajax_utils';
  import GrowthAssessmentChart from './components/GrowthAssessmentChart';
  import StandardsCategoryList from './StandardsCategoryList';
  import StandardsListByRange from './StandardsListByRange';
  import StandardsDetails from './StandardsDetails';
  import useStudentDetailReportStore from './stores/use_student_detail_report_store';

  const props = defineProps({
    availableSets: { required: true, type: String },
    config: { required: true, type: String },
    errorIconPath: { required: true, type: String },
    gradeCategoriesUrl: { required: true, type: String },
    reviewPath: { required: true, type: String },
    rosterPath: { required: true, type: String },
    rosterStudentList: { required: true, type: String },
    selectedStandardGuid: { required: false, type: String, default: '' },
    standardsAssigningUrl: { required: true, type: String },
    standardSet: { required: true, type: String },
    standardsLandingPagePath: { required: false, type: String, default: '' },
    studentId: { required: true, type: String },
    successIconPath: { required: true, type: String },
    unitSelected: { required: false, type: String, default: null },
  });

  const { cumulative_average } = JSON.parse(props.config);
  const standardCategory = reactive({ list: {}});
  const standardListByRange = reactive({ list: {}});
  const summary = reactive({ list: {}});
  const unit = reactive({ id: 0 });
  const standardDetails = reactive({ list: {}});
  const unitName = reactive({ label: ''});
  const gradeCategoriesUrlRef = ref(props.gradeCategoriesUrl);
  const availableSetsRef = ref(props.availableSets);
  const standardSetRef = ref();
  const URLStandardsCategoryByRange = ref(null);
  const unitSelectedParsed = JSON.parse(props.unitSelected);
  const rosterStudentListJSON = ref(JSON.parse(props.rosterStudentList));
  const currentRosterStudent = ref(props.studentId);
  const store = useStudentDetailReportStore();

  const standardCategoryStatus = computed(() => {
    return standardCategory.list && Object.keys(standardCategory.list).length > 0;
  });

  const availableSets = computed(() => {
    const availableSetsData = JSON.parse(availableSetsRef.value);
    const standardSetIdArray = [];
    Object.values(availableSetsData).forEach((set) => {
      standardSetIdArray.push({
        display_name: set[0].display_name,
        ids: set.map((set) => set.id).join(','),
      });
    });
    return standardSetIdArray;
  });

  const gradeCategoriesUrl = computed({
    get() {
      return gradeCategoriesUrlRef.value;
    },
    set(standardsIds) {
      gradeCategoriesUrlRef.value = props.gradeCategoriesUrl.replace(
        /standards\/\d+\/student_detail_report/,
        `standards/${ standardsIds }/student_detail_report`
      );
    },
  });

  const tooltipInfo = {
    standardsAssessed: {
      text: 'The name of the standards that were assessed as part of this unit.',
      position: 'top',
    },
    percentage: {
      text: 'Percent score achieved by student on the individual standard. This is calculated by dividing the points achieved by the total points possible.',
      position: 'top',
    },
    items: {
      text: 'Total number of questions presented for the individual standard.',
      position: 'top',
    },
    score: {
      text: 'Score achieved by student on the individual standard presented in a specific assessment.',
      position: 'top',
    },
  };

  onMounted(function() {
    loadDefaultStandardSet();
    if (unitSelectedParsed) {
      setStandardCategoryByUnit(unitSelectedParsed);
    }
  });

  /**
   * Set default standard set in the correct format.
   */
  function loadDefaultStandardSet() {
    const defaultStandardSet = availableSets.value.filter((set) => set.ids.includes(props.standardSet));
    if (defaultStandardSet && defaultStandardSet.length > 0) {
      standardSetRef.value = defaultStandardSet[0].ids;
      store.setSelectedStandardSetRef(defaultStandardSet[0].display_name);
    }
  }

  /**
   * Get infor to fill standards category list by unit ID.
   * @param {int} unitId
   */
  function setStandardCategoryByUnit(unitData) {
    store.setSelectedUnitId(unitData.id);
    unit.id = parseInt(unitData.id);
    unitName.label = unitData.name;

    const URLStandardsCategory = `${ gradeCategoriesUrl.value }${ unit.id }`;
    standardDetails.list = {};
    ajaxUtils.getFromEndpoint(
      URLStandardsCategory,
      (response) => {
        standardCategory.list = response.assessments;
      }
    );

    getStandardsRange(unit.id);
  }

  /**
   * Get info to fill standards list by unit ID and range.
   * @param {int} unitId
   * @param {int} lower
   * @param {int} upper
   */
  function getStandardsRange(unitId, lower = 0, upper = 100) {
    store.setSelectedStandardId('');
    store.setSelectedAssessmentIDs('');
    URLStandardsCategoryByRange.value = `${ gradeCategoriesUrl.value }
      ${unitId}/lower/${lower}/upper/${ upper }`;
    standardDetails.list = {};
    ajaxUtils.getFromEndpoint(
      `${URLStandardsCategoryByRange.value}/sort/1/column/percent_correct`,
      (response) => {
        summary.list = response.summary;
        standardListByRange.list = response.assessments;
      }
    );
  }

  /**
   * Get standard Details to show in the standard details table.
   * @param {Event} filter
   */
  function getStandardDetails(standardData) {
    store.setSelectedStandardId(standardData.id);
    const assessmentIDs = summary.list[standardData.standard_guid] ? Object.keys(summary.list[standardData.standard_guid]) : [];
    store.setSelectedAssessmentIDs(assessmentIDs.join(','));
    standardDetails.list = { ...standardData };
  }

  /**
   * Update standardCategory.list when standard set dropdown is changed.
   * @param {any} event
   */
  function handleStandardSetDropdown() {
    const selectedStandardSet = availableSets.value.find((s) => s.ids === standardSetRef.value);
    if (selectedStandardSet) {
      store.setSelectedStandardSetRef(selectedStandardSet.display_name);
    }
    gradeCategoriesUrl.value = standardSetRef.value;
    const URLStandardsCategory = `${ gradeCategoriesUrl.value }${ unit.id }`;

    ajaxUtils.getFromEndpoint(
      URLStandardsCategory,
      (response) => {
        standardListByRange.list = {};
        summary.list = {};
        standardDetails.list = {};
        standardCategory.list = response.assessments;
      }
    );

    getStandardsRange(unit.id);
  }

  /**
   * Do a fetch to get the standard list sorted
   * @date 2024-03-05
   * @param {int} sort
   * @param {string} type
   */
  function sortStandardList(sort, type) {
    ajaxUtils.getFromEndpoint(
      `${URLStandardsCategoryByRange.value}/sort/${ sort ? 1 : 0 }/column/${ type }`,
      (response) => {
        standardListByRange.list = response.assessments;
      }
    );
  }

  /**
   * Reload the page setting the student_id to show student data.
   */
  function changeStudentRoster() {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = props.standardsLandingPagePath;

    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = 'student_id';
    input.value = currentRosterStudent.value;
    form.appendChild(input);
    const tokenInput = document.createElement('input');
    tokenInput.type = 'hidden';
    tokenInput.name = 'authenticity_token';
    tokenInput.value = metaTagContent('csrf-token');
    form.appendChild(tokenInput);
    document.body.appendChild(form);
    form.submit();
  }
</script>

<style lang="scss" scoped>
@import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .chart-header {
    height: 6.2rem;
    margin: 1.0rem 0 2.3rem 0;
  }

  .return-icon {
    margin-right: 0.5rem;
  }

  .return-link {
    margin-right: 6%;
    padding-left: 1.5rem;
    padding-top: 0.3125rem;
    width: 9.5%;
  }

  .return-link-text {
    letter-spacing: 0.125rem;
  }

  .student-name {
    display: flex;
    border-right: rpx(1) solid $gray-e;
    letter-spacing: 0.1rem;
    padding-top: 0.375rem;
    width: 33%;

    .c-select {
      font-size: rpx(18);
      margin-left: 5rem;
    }
  }

  .cumulative-average {
    border-right: rpx(1) solid $gray-e;
    display: flex;
    letter-spacing: 0.1rem;
    justify-content: center;
    padding-top: 0.3125rem;
    width: 33%;
  }

  .average {
    font-size: 3.28rem;
    margin-top: -0.45rem;
  }

  .how-to-use {
    padding-top: 2rem;
    width: 33%;

    & span {
      letter-spacing: 0.05rem;
    }
  }

  .standards-breakdown {
    display: flex;
    justify-content: center;
    flex-direction: column;

    &__header {
      display: flex;
      flex-direction: row;
      justify-content: space-between;
      align-items: center;
      margin: 0 7%;
      padding: 3rem 0 1rem 0;
      border-bottom: 1px solid $gray-e;
    }

    &__header-item {
      h2 {
        font-size: rpx(18);
      }

      .standard-set-dropdown-label {
        text-transform: uppercase;
        color: $gray-6;
        font-size: rpx(16);
      }

      .standard-set-dropdown {
        font-size: rpx(16);
      }
    }

    &__container {
        margin-left: 6%;
        margin-right: rpx(-32);
    }

    &__section:nth-child(1) {
      width: 25%;
      margin: 0;
    }

    &__section:nth-child(2) {
      width: 40%;
      padding: 0 1rem;
      margin: 0;
    }

    &__section:nth-child(3) {
      width: 35%;
      margin: 0;
    }
  }

  .is-disabled {
    border-color: $gray-c;
    cursor: not-allowed;
  }
</style>
