<template>
  <div
    class="section-report-table  sticky-table-comp"
    :class="{
      'section-report-table--by-assessment': isPMRAssessment,
      [testClass('section-report-table-by-assessment')]: isPMRAssessment,
      'section-report-table--by-standards': isPMRStandards,
      [testClass('section-report-table-by-standards')]: isPMRStandards,
    }">
    <div
      ref="refScrollCnt"
      class="scroll-container">
      <table
        v-if="tableData"
        class="report-table"
        :class="testClass('section-summary-table')">
        <caption
          class="u-screen-reader-only"
          :class="testClass('section-summary-table-caption')">
          {{ tableCaption }}
        </caption>
        <thead>
          <tr
            :class="testClass('section-summary-table-header')"
            class="report-table-header-row">
            <th
              scope="col"
              class="corner-header-cell">
              <div
                class="corner-header-cell-content"
                :class="testClass('display-header-text')">
                {{ headerText1 }}
              </div>
              <div
                class="dummy-second-header-cell-content"
                :class="testClass('display-header-text')">
                {{ headerText2 }}
              </div>
            </th>
            <th
              scope="col"
              class="second-header-cell">
              <div class="second-header-cell-content">
                <!--
                We made this cell empty (ie no text eg "Standards") here as we are using
                a dummy sticky div in the first cell itself to solve some UI issues
                with sticky headers
                while scrolling -->
              </div>
            </th>
            <th
              v-if="headerColspan()"
              :colspan="headerColspan()"
              :class="testClass('header-row-filling-cell')"
              class="filling-cell" />
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="(tableRowData, rowIndex) in tableData"
            :key="rowIndex"
            class="report-table-data-row"
            :class="[
              testClass('table-data-row'),
              testClass(`table-data-row-${rowIndex + 1}`)
            ]">
            <!--
              Note: The sticky headers in this component were creating UI related issues eg -
              - boxshadow was not coming on 'th' tags
              - and left borders of sticky row headers were not sticky.
              So, to solve those issues, we had to add some extra divs and then moved
              box shadow and border properties to those div elements.
              -->
            <th
              scope="row"
              :class="getCategoryCls(tableRowData.category)"
              class="row-header-cell">
              <div class="first-row-offset" />
              <div class="row-header-cell-border">
                <div class="row-header-cell-content">
                  <template v-if="isPMRAssessment">
                    <span
                      class="row-header-txt  pmr-assessment-txt"
                      :class="testClass('row-header-txt')">
                      {{ tableRowData.label }}
                    </span>
                    <span>
                      <span class="assessment-counts-wrapper">
                        <span
                          class="assessment-counts-icon"
                          :class="testClass('assessment_counts_icon')">
                          <vhl-assessment-count-icon-gray
                            class="u-dis-inline-flex"
                            size="sm" />
                        </span>
                        <span
                          class="attempted-student-count"
                          :class="testClass('attempted-student-count')">
                          <span>{{ tableRowData.submission_count }}</span>
                          of
                          <span>{{ tableRowData.student_count }}</span>
                        </span>
                      </span>
                    </span>
                  </template>
                  <template v-if="isPMRStandards">
                    <a
                      aria-label="Find matching content button"
                      :class="testClass('find-matching-content')"
                      role="button"
                      target="_blank"
                      title="Find Matching Content"
                      :href="findMatchingContentUrl(tableRowData)">
                      <div class="u-search-button">
                        <vhl-magnifying-glass-icon size="md" />
                      </div>
                    </a>
                    <span
                      class="row-header-txt  js-standard-title-box"
                      :class="testClass('row-header-txt')"
                      @mouseenter="showTooltipOnRowHeaderCell($event, tableRowData)"
                      @mouseleave="hideTooltip()">
                      <a
                        href="javascript://"
                        class="js-tooltip-auto  u-dis-block"
                        :class="testClass('linked-standard')"
                        @click="goToDetailFromStandardLink(tableRowData)">
                        <span>
                          {{ tableRowData.label }}
                        </span>
                      </a>
                    </span>
                  </template>
                </div>
              </div>
            </th>
            <template
              v-for="(activity, dataIndex) in tableRowData.activities">
              <td
                v-if="showDataCell(activity)"
                :key="dataIndex"
                class="data-cell"
                :class="[
                  testClass('data-cell'),
                  testClass(`data-cell-${dataIndex + 1}`)
                ]"
                @click="goToDetailFromResultCell(activity)"
                @mouseenter="showTooltipOnDataCell($event, activity)"
                @mouseleave="hideTooltip">
                <div class="first-row-offset" />
                <div v-if="activity.result !== null" class="data-cell-content">
                  <div
                    class="data-percent-box  js-data-percent-box"
                    :class="[
                      activity.percentage_color,
                      testClass('data-percent-box')
                    ]">
                    {{ activity.percentage_format }}
                  </div>
                  <div
                    class="data-desc-box"
                    :class="testClass('data-desc-box')">
                    {{ activity.result }}
                  </div>
                </div>
              </td>
            </template>
            <td
              v-if="cellColSpan(tableRowData.activities)"
              :colspan="cellColSpan(tableRowData.activities)"
              class="filling-cell"
              :class="testClass('data-row-filling-cell')">
              <div class="first-row-offset" />
              <div class="data-cell-content">
                <span />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
  <!-- eslint-disable vue/no-multiple-template-root -->
  <Tooltip
    v-show="tooltip.visible"
    :mode="tooltip.mode"
    :categoryName="tooltip.categoryName"
    :title="tooltip.title"
    :description="tooltip.description"
    :position="tooltip.position" />
  <!-- eslint-enable vue/no-multiple-template-root -->
</template>
<script setup>
  import { testClass } from 'music';
  import { computed, onMounted, onUnmounted, reactive, ref } from 'vue';
  import Tooltip from 'features/gradebook/standards/section_report/Tooltip';
  import { TableModes } from 'features/gradebook/standards/section_report/consts';

  const props = defineProps({
    standardsAssigningUrl: { default: '', type: String },
    tableCaption: { required: true, type: String },
    tableData: { required: true, type: Object },
    tableMode: {
      required: true,
      type: String,
      validator: (value) => {
        return [
          'byPMRAssessment',
          'byPMRStandards',
          'pmrSingleStandard',
          'pmrStudents',
        ].includes(value);
      },
    },
    unitId: { default: 0, type: Number },
  });
  const emit = defineEmits(['showFiltersSection', 'showStandardSingleRow']);

  const isPMRAssessment = computed(() => props.tableMode === TableModes.byPMRAssessment);
  const isPMRStandards = computed(() => props.tableMode === TableModes.byPMRStandards);
  const maxCellCount = computed(getMaximumDataCellCount);
  const refScrollCnt = ref(null);
  const tooltip = reactive({
    categoryName: '',
    description: '',
    mode: 'standard',
    position: {
      left: 0,
      top: 0,
      topOffset: 0,
    },
    title: '',
    visible: false,
  });

  /**
   * Get text for first cell in table header,
   * indicating the primary field based on report view.
   * @return {string}
   */
  const headerText1 = computed(() => {
    return isPMRAssessment.value ? 'Progress Monitoring' : 'Standards';
  });

  /**
   * Get text for 2nd cell in table header,
   * indicating the data fields, based on report view.
   * @return {string}
   */
  const headerText2 = computed(() => {
    return isPMRAssessment.value ? 'Standards' : 'Assessment';
  });

  /**
   * Get url to navigate to Find Matching Content
   * @param {Object.<string, object>} tableRowData - Data corresponding to a row.
   * @return {string}
   */
  const findMatchingContentUrl = (tableRowData) => {
    return props.standardsAssigningUrl +
      `?standards=${tableRowData.id}&selected_unit=${props.unitId}`;
  };

  /**
   * Emit event to navigate to detail page.
   * @param {Object.<string, object>} tableRowData - Data corresponding to a row.
   */
  const goToDetailFromStandardLink = (tableRowData) => {
    const standardId = tableRowData.id;
    emit('showStandardSingleRow', standardId);
  };

  /**
   * Emit event to navigate to detail page.
   * @param {Object.<string, object>} cellData - Data corresponding to a data cell.
   */
  const goToDetailFromResultCell = (cellData) => {
    if (isPMRAssessment.value) {
      const standardId = cellData.standard_id;
      emit('showStandardSingleRow', standardId);
    }
  };

  /**
   * Whether a data cell should be visible.
   * @param {Object.<string, object>} activity - Data corresponding a cell.
   * @return {bool}
   */
  const showDataCell = (activity) => {
    return !!activity.result;
  };

  /**
   * Get UI mode for the tooltip
   * @param {bool} isRowHeader
   * @return {string}
   */
  function getTooltipMode(isRowHeader) {
    if (isPMRStandards.value) {
      if (isRowHeader) {
        return 'show-standard-desc';
      } else {
        return 'show-activity-info';
      }
    } else if (isPMRAssessment.value) {
      return 'show-standard';
    }
  }

  /**
   * Show tooltip when hover on a data cell in the table.
   * @param {Event} event
   * @param {object.<string, object>} cellData
   */
  function showTooltipOnDataCell(event, cellData) {
    const mode = getTooltipMode(false);
    if (isPMRStandards.value) {
      const description = `(${cellData.submission_count} of ${cellData.student_count})`;
      showTooltip(event, mode, cellData.activity_name, description, cellData.category);
    } else if (isPMRAssessment.value) {
      showTooltip(event, mode, cellData.standard_name, cellData.standard_description);
    }
  }

  /**
   * Show tooltip when hover on a row header cell in the table.
   * @param {Event} event
   * @param {object.<string, object>} rowData
   */
  function showTooltipOnRowHeaderCell(event, rowData) {
    if (isPMRStandards.value) {
      const mode = getTooltipMode(true);
      showTooltip(event, mode, '', rowData.description);
    }
  }

  /**
   * Show tooltip when hover.
   * @param {Event} event
   * @param {string} mode
   * @param {string} title
   * @param {string} description
   * @param {string} categoryName
   */
  function showTooltip(event, mode, title, description, categoryName) {
    console.log('showTooltip');
    let mainBox;
    if (event.target.classList.contains('js-standard-title-box')) {
      mainBox = event.target;
    } else {
      mainBox = event.target.querySelector('.js-data-percent-box');
    }
    if (!mainBox) return;

    const rect = event.target.getBoundingClientRect();
    const mainRect = mainBox.getBoundingClientRect();
    const left = mainRect.left + window.scrollX + mainRect.width / 2;
    const top = rect.top + window.scrollY;
    tooltip.visible = true;
    tooltip.title = title;
    tooltip.description = description;
    tooltip.categoryName = categoryName;
    tooltip.mode = mode;
    tooltip.position = {
      left,
      top,
      topOffset: mode === 'show-standard-desc' ? 28 : 12,
    };
  }

  /**
   * Hide tooltip.
   */
  function hideTooltip() {
    tooltip.visible = false;
  }

  /**
   * Get maximum value count of cells with result data of any of the rows.
   * @return {number}
   */
  function getMaximumDataCellCount() {
    const countInRow = [];
    props.tableData?.forEach((rowData) => {
      const dataCount = rowData.activities?.filter((act) => act.result)?.length ?? 0;
      countInRow.push(dataCount);
    });
    return Math.max(...countInRow) ?? 0;
  }

  /**
   * Get count cells with result data in the given row.
   * @param {Array.<object>} activities Array of result data for a row
   * @return {number}
   */
  function getDataCellCount(activities) {
    return activities.filter((act) => act.result).length;
  }

  /**
   * Get colspan for an extra th added by us to make width flow
   * and take remaining with in header row.
   * @return {number}
   */
  const headerColspan = () => {
    return maxCellCount.value;
  };

  /**
   * Get colspan for an extra td added by us to make width flow
   * and take remaining with in each data row.
   * @param {Array.<object>} activities
   * @return {number}
   */
  const cellColSpan = (activities) => {
    let dataCellsCount = getDataCellCount(activities);
    if (dataCellsCount === null || dataCellsCount === undefined) {
      return 1;
    }
    dataCellsCount = dataCellsCount?? 0;
    return maxCellCount.value - dataCellsCount + 1;
  };

  /**
   * Get catagory specific css class for each data row
   * @param {string} categoryName
   * @return {string}
   */
  function getCategoryCls(categoryName) {
    const categoryCls = {
      'Quizzes': 'category--quizzes',
      'Unit Test': 'category--unit_test',
      'Speaking and Writing Tests': 'category--speaking_and_writing_tests',
    };
    return categoryCls[categoryName] ?? '';
  }

  onMounted(()=> {
    bindScrollEvents();
  });

  onUnmounted(unbindScrollEvents);

  /**
   * Bind scroll events to hide tooltip.
   * window is used for v-scroll and scrollCnt is for h-scroll.
   */
  function bindScrollEvents() {
    window.addEventListener('scroll', hideTooltip);
    const scrollCnt = refScrollCnt.value;
    scrollCnt.addEventListener('scroll', hideTooltip);
  }

  /**
   * Unbind scroll events for cleanup.
   */
  function unbindScrollEvents() {
    document.removeEventListener('scroll', hideTooltip);
    const scrollCnt = refScrollCnt.value;
    scrollCnt?.removeEventListener('scroll', hideTooltip);
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  /*
  Note: Current limitation of this sticky headers is that
  it uses fixed height approach for all rows, in order to
  keep sticky headers without any border and box-shadow issues.
  So the row header text should not be wrapped else it will be cut.
  */
  $header-height: rpx(56);
  $row-height: rpx(96);
  $first-row-offset: rpx(4);
  $border-offset: rpx(4);
  $padding-after-border-offset: rpx(12);

  .section-report-table--by-standards,
  .section-report-table--by-assessment {
    &.section-report-table {
      background: white;
      background-color: $white;
      border: 0;
      border-left: rpx(1) solid #F5F5F5;
      border-radius: rpx(5);
      box-shadow: none;
      box-sizing: border-box;
      display: block;
      padding: 0;
      padding-left: rpx(2);
      width: 100%;
    }
    .scroll-container {
      overflow-x: auto;
    }
    .report-table {
      border: 0;
      border-collapse: collapse;
      margin: 0;
      padding: 0;
      width: 100%;
    }
    .report-table-header-row {
      background-color: #F5F5F5;
    }
    .report-table-data-row {
      background-color: $white;
      border-top: rpx(1) solid $gray-d;
      transition: background-color 0.3s;

      &:hover {
        background: #f8f8f8;
      }
    }
    .corner-header-cell,
    .second-header-cell {
      border-left: 0;
      color: $gray-3 !important;
      font-weight: 400 !important;
      text-align: left;
      width: rpx(160);
    }
    .corner-header-cell {
      background-color: #F5F5F5;
      left: 0;
      padding: 0;
      position: sticky;
      z-index: 2;
    }
    .second-header-cell {
      font-size: rpx(16);
      padding: rpx(8);
      width: auto;
    }
    .report-table th {
      white-space: nowrap;
    }
    .filling-cell {
      padding: 0;
      width: auto;
    }
    .filling-cell .data-cell-content {
      margin: 0;
      padding: 0;
    }
    .report-table-data-row > td.filling-cell {
      min-width: rpx(8);
      /* this is needed because otherwise first-row-offset takes too much width
      and creates additional horizontal scroll otherwise.
      */
      position: relative;
    }
    .row-header-cell {
      background-color: $white;
      font-weight: 400 !important;
      left: 0;
      padding: 0;
      position: sticky;
      text-align: left;
      width: rpx(160);
      z-index: 2;

      &:hover {
        background: #f8f8f8;
      }
    }
    .row-header-cell-content {
      border-bottom: rpx(1) solid #ddd;
      box-shadow: rpx(3) 0 rpx(9) rgba(0, 0, 0, 0.1);
      display: inline-flex;
      flex-direction: column;
      font-size: rpx(16);
      height: rpx(96);
      justify-content: center;
      margin-left: $border-offset;
      padding: 0;
      padding-left: $padding-after-border-offset;
      padding-right: rpx(16);
      width: calc(100% - $border-offset);
    }
    .corner-header-cell-content,
    .dummy-second-header-cell-content {
      display: inline-flex;
      flex-direction: column;
      font-size: rpx(16);
      height: $header-height;
      justify-content: center;
    }
    .corner-header-cell-content {
      box-shadow: rpx(3) 0 rpx(9) rgba(0, 0, 0, 0.1);
      padding: 0 rpx(24);
      width: 100%;
    }
    .dummy-second-header-cell-content {
      background-color: #F5F5F5;
      margin-left: rpx(8);
      padding: 0 rpx(16);
    }
    .row-header-txt {
      color: $gray-3;
      font-size: 1rem;
    }
    .assessment-counts-icon {
      padding-right: rpx(2);
    }
    .attempted-student-count {
      color: #707070;
      font-size: rpx(14);
    }
    .data-cell {
      padding: 0;
      position: relative;
    }
    .data-cell-content {
      border-bottom: rpx(1) solid #ddd;
      display: inline-flex;
      flex-direction: column;
      height: $row-height;
      justify-content: center;
      padding-left: rpx(16);
      padding-right: rpx(16);
      text-align: left;
      width: 100%;
    }
    .report-table-header-row th,
    .report-table-header-row td,
    .report-table-data-row th,
    .report-table-data-row td {
      border-bottom: 0;
    }
    &.sticky-table-comp {
      .second-header-cell-content {
        display: none;
      }
      .report-table-data-row {
        border-top: 0;
      }
    }
    tr td:first-of-type .data-cell-content {
      padding-left: rpx(42);
    }
    tbody tr:first-child {
      .first-row-offset {
        background-color: $white;
        height: rpx(4);
        position: absolute;
        width: 100%;
      }
      .row-header-cell-border,
      .data-cell-content {
        margin-top: $first-row-offset;
      }
    }
    .category--quizzes .row-header-cell-border {
      border-left: rpx(4) solid #EF2121;
    }
    .category--unit_test .row-header-cell-border {
      border-left: rpx(4) solid #5570FE;
    }
    .category--speaking_and_writing_tests .row-header-cell-border {
      border-left: rpx(4) solid #FEE355;
    }
    .data-percent-box {
      background: $gray-e;
      border: rpx(1) solid $gray-e;
      border-radius: rpx(8);
      color: $gray-3;
      display: inline-block;
      font-size: rpx(16);
      line-height: 2.275rem;
      margin: 0;
      margin-right: auto;
      min-width: 2.7rem;
      padding: 0.15rem;
      text-align: center;
    }
    .u-percent-90-to-100 {
      background: #C5FFCE;
      border-color: #007112;
      color: inherit;
    }
    .u-percent-80-to-89 {
      background: rgba(231, 255, 235, 0.939);
      border-color: #16990B;
      color: inherit;
    }
    .u-percent-70-to-79 {
      background: #FFF598;
      border-color: #D17100;
      color: inherit;
    }
    .u-percent-60-to-69 {
      background: #FFD7A8;
      border-color: #E73700;
      color: inherit;
    }
    .u-percent-0-to-59 {
      background: #FFD7D7;
      border-color: #A91313;
      color: inherit;
    }
    .data-desc-box {
      color: #707070;
      margin-top: rpx(2);
      white-space: nowrap;
    }
    .report-table-header-row > th:first-child,
    .c-row > th {
      box-shadow: rpx(3) 0 rpx(9) rgba(0, 0, 0, 0.1);
    }
    td {
      width: rpx(80);
    }
  }

  .section-report-table--by-standards {
    &.sticky-table-comp .row-header-cell-content {
      align-items: center;
      flex-direction: row;
      justify-content: flex-start;
      margin-left: 0;
      padding-left: rpx(24);
      padding-bottom: rpx(32);
      width: 100%;
    }

    .row-header-txt {
      display: inline-block;
      margin-left: rpx(16);
    }
  }

  .section-report-table--by-assessment {
    .data-cell {
      cursor: pointer;
    }

    .pmr-assessment-txt {
      min-width: rpx(400);
      text-wrap: wrap;
    }
  }
</style>
