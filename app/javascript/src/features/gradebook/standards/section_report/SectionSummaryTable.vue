<template>
  <div
    class="u-table-container"
    :class="{
      'table-mode--pmr-single-standard': isPMRSingleStandard,
      [testClass('table-mode-pmr-single-standard')]: isPMRSingleStandard,
      'table-mode--pmr-students': isPMRStudents,
      [testClass('table-mode-pmr-students')]: isPMRStudents,
    }">
    <table
      v-if="columnHeadersFormated.data.length > 0"
      class="c-table  c-table--content  u-section-table  u-width-full"
      :class="testClass('section-summary-table')">
      <caption class="u-screen-reader-only">
        {{ props.tableCaption }}
      </caption>
      <thead>
        <tr class="c-header-row">
          <th
            scope="col"
            class="u-txt-gray-3  u-txt-lt  u-txt-reg  table-header"
            :class="testClass('table-header')"
            :aria-sort="sortDirection(mainHeaderColumn.data?.sortDirection)"
            :aria-description="sortDirection(mainHeaderColumn.data?.sortDirection) ? 'Click to sort' : null"
            @click="SortableColumn(mainHeaderColumn.data?.id)">
            <a
              href="javascript://"
              class="c-sorting-header">
              <span class="u-txt-16  c-txt-capitalize" :class="testClass('header-text')">
                {{ mainHeaderColumn.data?.id == 'standard' ? 'Standards' : mainHeaderColumn.data?.id }}
              </span>
              <span
                v-if="!props.isSingleRow"
                role="img"
                aria-label="column sort state icon">
                <vhl-column-ascending-icon
                  v-if="mainHeaderColumn.data?.sortDirection === 'asc'"
                  class="c-sort-icon  u-pad-0"
                  size="sm" />
                <vhl-column-descending-icon
                  v-if="mainHeaderColumn.data?.sortDirection === 'desc'"
                  class="c-sort-icon  u-pad-0"
                  size="sm" />
                <vhl-column-unsorted-icon
                  v-if="mainHeaderColumn.data?.sortDirection === null"
                  class="c-sort-icon  u-pad-0"
                  size="sm" />
              </span>
            </a>
          </th>
          <template
            v-for="(headerValue, headerKey) in columnHeadersFormated.data"
            :key="headerKey">
            <th
              v-if="!isSortableHeader(headerValue.id)"
              scope="col"
              class="u-txt-gray-3"
              :class="[
                testClass('table-header'),
                isPMRSingleStandard || isPMRStudents ? 'pmr-cell-space' : 'u-txt-ctr'
              ]"
              :aria-sort="sortDirection(headerValue?.sortDirection)"
              :aria-description="sortDirection(headerValue?.sortDirection) ? 'Click to sort' : null"
              @click="SortableColumn(headerValue?.id)">
              <a
                href="javascript://"
                :class="testClass(`standard-assessment-${headerValue?.id}-column`)"
                class="c-sorting-header">
                <span :class="testClass('header-text')">
                  {{ headerValue.label }}
                </span>
                <span
                  v-if="!props.isSingleRow"
                  role="img"
                  aria-label="column sort state icon">
                  <vhl-column-ascending-icon
                    v-if="headerValue.sortDirection === 'asc'"
                    class="c-sort-icon  u-pad-0"
                    size="sm" />
                  <vhl-column-descending-icon
                    v-if="headerValue.sortDirection === 'desc'"
                    class="c-sort-icon  u-pad-0"
                    size="sm" />
                  <vhl-column-unsorted-icon
                    v-if="headerValue.sortDirection === null"
                    class="c-sort-icon  u-pad-0"
                    size="sm" />
                </span>
                <br>
                <span v-if="props.tableType === 'standard'">
                  <span class="u-txt-reg  u-pad-rt-16">
                    <span :class="['u-pad-rt-2', testClass('assessment_counts_icon')]">
                      <vhl-assessment-count-icon class="u-mar-bot-6" size="sm" />
                    </span>
                    <span :class="testClass('submission-count-info-txt')">
                      <span :class="testClass('graded-count')">{{ headerValue?.scoreCount }}</span>
                      of
                      <span :class="testClass('student-count')">{{ headerValue?.studentCount }}</span>
                    </span>
                  </span>
                </span>
              </a>
            </th>
          </template>
          <th
            v-if="!tableSummaryData.value?.assistant_role_policy && props.tableType === 'standard'"
            :class="testClass('find-matching-content')"
            class="u-txt-ctr  u-txt-reg  u-txt-gray-3">
            Find Matching<br>Content
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(data, key) in tableSummaryData"
          :key="key"
          :class="['c-row u-pad-4', testClass('result-row')]">
          <th scope="row" class="l-stack-sm  u-txt-reg  u-pad-8">
            <template v-if="props.isSingleRow">
              <sl-tooltip
                  class="standard-description-tooltip"
                  :class="testClass('standard-tooltip')"
                  :content="data.description">
                <p
                  class="js-tooltip-auto  u-dis-block  u-mar-0">
                  <vhl-thick-arrow-icon
                    size="md"
                    rotate="1" />
                  <span :class="testClass('row-header-txt')">
                    {{ data.label }}
                  </span>
                </p>
              </sl-tooltip>
              <span
                v-if="isPMRSingleStandard"
                :class="[{ 'u-pad-lt-20': props.isSingleRow }, testClass('item-count')]">
                {{ data.total_number_of_items }} Items
              </span>
            </template>
            <template v-else>
              <template v-if="props.tableType === 'standard'">
                <sl-tooltip
                  class="standard-description-tooltip"
                  :class="testClass('standard-tooltip')"
                  :content="data.description">
                  <a
                  href="javascript://"
                  class="js-tooltip-auto  u-dis-block"
                  :class="testClass('linked-standard')"
                  @click="$emit('showStandardSingleRow',{
                    report_rows: {
                      column_headers: [columnHeaders],
                      data: [data]
                    }
                  })">
                    <span>
                      {{ data.label }}
                    </span>
                  </a>
                </sl-tooltip>
                <span
                  :class="[{ 'u-pad-lt-20': props.isSingleRow }, testClass('item-count')]">
                  {{ data.total_number_of_items }} Items
                </span>
              </template>
              <template v-else>
                <a
                  v-if="isPMRStudents"
                  :href="linkToGradebookPage(data)"
                  target="_blank"
                  :class="testClass('link-to-gradebook')">
                  {{ data.name }}
                </a>
                <a
                  v-else
                  href="javascript://"
                  :class="testClass('unlinked-standard')"
                  @click="linkToStudentReport(data.student_link_data)">
                  {{ data.name }}
                </a>
              </template>
            </template>
          </th>
          <template
            v-for="(activity, activitykey) in data.activities"
            :key="activitykey">
            <td
              v-if="isPMRSingleStandard || isPMRStudents"
              :class="[
                'pmr-mode-cell',
                activity.result === null ? 'pmr-empty-cell-space' : 'pmr-cell-space'
              ]"
              @click="openReviewItemsModal($event, activity, data.student_link_data)">
              <span
                v-if="activity.result === null"
                class="u-percent-box"
                :class="testClass('no-grade-percent-box')"
                aria-label="No graded result">--</span>
              <span
                v-else
                class="u-dis-inline-flex">
                <span
                  class="u-percent-box-pmr"
                  :class="activity.percentage_color" />
                <span
                  class="u-mar-lt-8"
                  :class="testClass('data-percent-box')">
                  {{ activity.percentage_format }}
                </span>
              </span>
              <br>
            </td>
            <td
              v-else
              :class="activity.results_cell_classes"
              @click="openReviewItemsModal($event, activity, data.student_link_data)">
              <span
                v-if="activity.result === null"
                class="u-percent-box"
                aria-label="No graded result">--</span>
              <span
                v-else
                class="u-percent-box"
                :class="activity.percentage_color">
                {{ activity.percentage_format }}
              </span>
              <br>
              <span class="u-txt-lightest">
                {{ activity.result }}
              </span>
            </td>
          </template>
          <td v-if="props.standardsAssigningUrl" class="u-txt-ctr">
            <a
              aria-label="Find matching content button"
              :class="testClass('find-matching-content')"
              role="button"
              target="_blank"
              title="Find Matching Content"
              :href="`${props.standardsAssigningUrl}?standards=${data.id}&selected_unit=${props.unitId}`">
              <div class="u-search-button">
                <vhl-magnifying-glass-icon size="md" />
              </div>
            </a>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
<script setup>
  import { testClass } from 'music';
  import * as ajaxUtils from 'shared/ajax_utils';
  import { computed, onMounted, reactive, ref, watch } from 'vue';
  import { TableModes } from 'features/gradebook/standards/section_report/consts';
  import useSectionReportFilterStore from './../section_report_filters/stores/use_section_report_filter_store';

  const props = defineProps({
    courseId: { default: '', type: String },
    filtersData: { required: false, type: Object, default: null },
    isSingleRow: { required: false, type: Boolean, default: false },
    programId: { required: false, type: String, default: '' },
    sectionId: { required: false, type: String, default: '' },
    sortReportPath: { required: false, type: String, default: '' },
    standardId: { required: false, type: Number, default: null },
    standardsLandingPagePath: { type: String, required: false, default: '' },
    standardsAssigningUrl: { type: String, default: null },
    studentReportDataPath: { type: String, required: false, default: '' },
    tableCaption: { type: String, default: '' },
    tableData: { required: true, type: Object, default: null },
    tableType: { type: String, default: 'standard' },
    tableMode: {
      default: '',
      type: String,
      validator: (value) => {
        return value === '' || [
          'pmrSingleStandard',
          'pmrStudents',
        ].includes(value);
      },
    },
    unitId: { required: true, type: Number },
  });

  const store = useSectionReportFilterStore();
  const columnHeaders = ref(props.tableData?.report_rows.column_headers[0]);
  const columnHeadersFormated = reactive({ data: [] });
  const mainHeaderColumn = reactive({ data: {}});
  const currentSortInfo = reactive({ sort: props.tableType, direction: 'desc' });
  const tableSummaryData = ref(props.tableData?.report_rows.data);
  const isPMRSingleStandard = computed(() => props.tableMode === TableModes.pmrSingleStandard);
  const isPMRStudents = computed(() => props.tableMode === TableModes.pmrStudents);
  const emit = defineEmits(['showStandardSingleRow', 'openReviewItems']);

  watch(() => props.tableData?.report_rows.column_headers[0], (newValue) => {
    columnHeaders.value = newValue;
    formatTableHeadersData();
  });

  watch(() => props.tableData?.report_rows.data, (newValue, oldValue) => {
    tableSummaryData.value = newValue;
  });

  onMounted(()=> {
    formatTableHeadersData();
  });

  /**
   * Get the abbreviation for sort direction and returns the full sort direction name.
   * @param {String} sortValue
   * @return {String}
   */
  function sortDirection(sortValue) {
    switch (sortValue) {
    case 'asc':
      return 'ascending';
    case 'desc':
      return 'descending';
    }
  }

  /**
   * Emmit 'openReviewItems' event to open review items Modal.
   * @param {Event} event
   * @param {Object} activity
   * @param {Object} studentData
   */
  function openReviewItemsModal(event, activity, studentData) {
    if (event.currentTarget.classList.value.includes('js-reviewable-item')) {
      emit(
        'openReviewItems',
        {
          itemGuids: activity.item_guids,
          standardLabel: activity.standard_label,
          standardSetId: studentData.standard_set_id,
          studentId: studentData.student_id,
        }
      );
    }
  }

  /**
   * Do a post request to get the report data.
   */
  function getSortedData() {
    const simpleSortReportPath = props.sortReportPath.split('?')[0];
    const postParams = {
      assessment_ids: props.filtersData?.assessment_ids,
      direction: currentSortInfo.direction,
      lesson_id: props.filtersData?.lesson_id,
      sort: currentSortInfo.sort,
      standard_set_display_name: props.filtersData?.standard_set_display_name,
      assessment_type: props.filtersData?.assessment_type,
    };
    !props.standardId || (postParams.standard_id = props.standardId);
    ajaxUtils.postToEndpoint(
      simpleSortReportPath,
      postParams,
      (response) => {
        tableSummaryData.value = response.assessments.report_rows.data;
      }
    );
  }

  /**
   * Sort student performance table data without postback.
   * different logic will be used for text column 'student' and
   * percentage columns ie. assessment groups.
   * Further, 'student' column will be used as secondary sort for
   * other columns.
   * This method handles for progress monitoring assessment's use case.
   */
  function getClientSortedData() {
    tableSummaryData.value?.sort((rowA, rowB) => {
      if (currentSortInfo.sort === 'student') {
        return sortByStudentName(rowA, rowB, currentSortInfo.direction);
      } else {
        return sortByScorePercentage(rowA, rowB, currentSortInfo.sort, currentSortInfo.direction);
      }
    });
  }

  /**
   * This is compare function for sorting student performance table
   * by student names.
   * @param {object.<string, object>} rowA - dataRow in the table data.
   * @param {object.<string, object>} rowB - dataRow in the table data.
   * @param {string} direction
   * @return {number}
   */
  function sortByStudentName(rowA, rowB, direction) {
    return direction === 'asc' ?
      rowA.name.localeCompare(rowB.name) :
      rowB.name.localeCompare(rowA.name);
  }

  /**
   * Get cell data for related to the column which is being sorted.
   * @param {object.<string, object>} rowData - dataRow in the table data.
   * @param {string} sortKey - indicating the group/column of the table
   * to be sorted.
   * @return {object.<string, object>}
   */
  function getActivityCellData(rowData, sortKey) {
    return rowData.activities.find((_, index) => {
      const headerId = columnHeadersFormated.data[index + 1]?.id;
      return headerId === sortKey;
    });
  }

  /**
   * This is compare function for sorting student performance table
   * by score percentage value in some specific group.
   *
   * If primary sort values are equal, fall back to secondary sort
   * by student name. Secondary sort is always ascending.
   * @param {object.<string, object>} rowA - dataRow in the table data.
   * @param {object.<string, object>} rowB - dataRow in the table data.
   * @param {string} sortKey - indicating the group/column of the table
   * to be sorted.
   * @param {string} direction
   * @return {number}
   */
  function sortByScorePercentage(rowA, rowB, sortKey, direction) {
    const [percentageA, percentageB] = [
      getActivityCellData(rowA, sortKey),
      getActivityCellData(rowB, sortKey),
    ].map((cellData) =>
      parseActivityPercentage(cellData)
    );
    const primarySortResult = direction === 'asc' ?
      percentageA - percentageB :
      percentageB - percentageA;
    return primarySortResult === 0 ?
      sortByStudentName(rowA, rowB, 'asc') :
      primarySortResult;
  }

  /**
   * Get numerical value of student performance value expressed in percentage.
   * If its not numerical or null then use -1 to distinguish such items from 0%.
   * @param {object.<string, object>} cellData - data for a cell in the table
   * @return {number}
   */
  function parseActivityPercentage(cellData) {
    return isNaN(parseInt(cellData?.percentage_format)) ?
      -1 : parseInt(cellData?.percentage_format);
  }

  /**
   * Format the column headers to be renderend by the component.
   */
  function formatTableHeadersData() {
    if (columnHeaders.value) {
      columnHeadersFormated.data = [];
      Object.keys(columnHeaders.value).forEach((columnHeader) => {
        const headerRown = {
          id: columnHeader,
          label: columnHeaders.value[columnHeader].label,
          scoreCount: getSubmissionCount(columnHeaders, columnHeader),
          studentCount: getPossibleSubmissionsCount(columnHeaders, columnHeader),
          sortDirection: columnHeader === props.tableType ? 'asc' : null,
        };
        if (columnHeader === props.tableType) {
          mainHeaderColumn.data = headerRown;
        }
        columnHeadersFormated.data.push(headerRown);
      });
    }
  }

  /**
   * Get submission count for a specific assessment
   * or assessment group ie category.
   * This supports format for proficiency assessments and
   * progress monitoring assessments both, based on table mode.
   * @param {Array.<object>} columnHeaders
   * @param {String} columnHeader
   * @return {number}
   */
  function getSubmissionCount(columnHeaders, columnHeader) {
    if (isPMRSingleStandard.value || isPMRStudents.value) {
      return columnHeaders.value[columnHeader].submission_count;
    } else {
      return columnHeaders.value[columnHeader].score_count;
    }
  }

  /**
   * Get submission count for a specific assessment
   * or assessment group ie category.
   * This supports format for proficiency assessments and
   * progress monitoring assessments both, based on table mode.
   * @param {Array.<object>} columnHeaders
   * @param {String} columnHeader
   * @return {number}
   */
  function getPossibleSubmissionsCount(columnHeaders, columnHeader) {
    if (isPMRSingleStandard.value || isPMRStudents.value) {
      return columnHeaders.value[columnHeader].possible_submissions_count;
    } else {
      return columnHeaders.value[columnHeader].student_count;
    }
  }

  /**
   * Get a table header name and returns true if is a table header, instead returns false.
   * @param {String} headerName
   * @return {Boolean}
   */
  function isSortableHeader(headerName) {
    return headerName.toLowerCase() === props.tableType;
  }

  /**
   * Get table info sorted by header column.
   * @param {Number} headerId
   */
  function SortableColumn(headerId) {
    currentSortInfo.sort = headerId;
    columnHeadersFormated.data.forEach((element, index) => {
      if (element.id === headerId) {
        const direction = element.sortDirection === 'desc' ? 'asc': 'desc';
        columnHeadersFormated.data[index].sortDirection = direction;
        currentSortInfo.direction = direction;
      } else {
        columnHeadersFormated.data[index].sortDirection = null;
      }
    });
    if (isPMRStudents.value) {
      getClientSortedData();
    } else {
      getSortedData();
    }
  }

  /**
   * Redirect to student report tab.
   * @param {Object} linkData
   */
  function linkToStudentReport(linkData) {
    sessionStorage.setItem('reportTabActive', 'student');
    /**
     * TODO: Refactor this to avoid refreshing the page.
     * Use Vue's reactive properties instead of reloading the form.
     */
    const plainLinkData = Object.assign({}, linkData);

    const form = document.createElement('form');
    form.method = 'POST';
    form.action = props.standardsLandingPagePath;

    Object.keys(plainLinkData).forEach((key) => {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = key;
      input.value = plainLinkData[key];
      form.appendChild(input);
    });

    const tokenInput = document.createElement('input');
    tokenInput.type = 'hidden';
    tokenInput.name = 'authenticity_token';
    tokenInput.value = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    form.appendChild(tokenInput);

    document.body.appendChild(form);
    form.submit();
  }

  /**
   * Go to gradbook page corresponding to the lesson id.
   * @param {Object.<string, object>} tableData
   * @return {string} Url to gradebook page with correct parameters.
   */
  function linkToGradebookPage(tableData) {
    const lessonId = tableData.student_link_data.lesson_id;
    return `/gradebook/${props.programId}/courses/${props.courseId}/sections/${props.sectionId}/scores` +
      `?lesson_or_due_date=lesson&all_lesson_or_week=${lessonId}&activities_strand_or_day=activity&category_id=&percent_or_points=Percentage`;
  }
</script>
<style  lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-sort-icon :deep(.c-svg-icon > svg) {
    height: inherit;
    margin-left: 0.1rem;
  }

  .table-mode--pmr-single-standard,
  .table-mode--pmr-students {
    .pmr-mode-cell:hover {
      background-color: transparent;
      box-shadow: none;
    }

    .pmr-mode-cell .u-percent-box {
      height: rpx(30);
      line-height: rpx(24);
      min-width: unset;
      width: rpx(30);
    }
  }

  .pmr-cell-space {
    padding-left: rpx(26);
    text-align: unset !important;
  }

  .pmr-empty-cell-space {
    padding-left: rpx(36);
    text-align: unset !important;
  }

  .table-header {
    width: 30%;
  }

  .c-txt-capitalize {
    text-transform: capitalize;
  }

  .standard-description-tooltip {
    --sl-tooltip-arrow-size: 0;
  }
</style>
