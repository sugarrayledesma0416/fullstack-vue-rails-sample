<template>
  <div class="l-grid  ns-music-v1">
    <div class="c-rubrics-alert-banner  u-width-full">
      <div
        v-show="rubric.showBannerAlert"
        class="c-rubrics-alert-banner__container"
        role="alert"
        aria-live="polite"
        aria-atomic="true"
        tabindex="0">
        <div
          class="c-rubrics-alert-banner__close-wrapper">
          <button
            type="button"
            class="c-no-button  is-navigable"
            @click="rubric.showBannerAlert = false">
            &times;
          </button>
        </div>
        <div class="c-rubrics-alert-banner__content">
          <button
            type="button"
            class="c-no-button  u-mar-8"
            @click="rubric.undoLastRemovedData">
            Recover the most recently removed data.
          </button>
        </div>
      </div>
    </div>
    <div class="l-col-12  u-pad-24">
      <div class="c-activity-rubric  rubric-editing-container">
        <table
          class="c-table  c-rubric-table  c-rubric-table--edit">
          <thead>
            <!-- gutter column header -->
            <tr class="c-header-row  c-header-row--gutter">
              <td
                class="gutter-no-actions" />
              <td
                :data-criteria-idx="0"
                :data-header-idx="0"
                :data-header-id="-1"
                data-cell-type="mix"
                data-droppable="true"
                class="gutter-no-actions"
                @dragover.prevent=""
                @drop.prevent="rubric.handleDrop" />
              <th
                v-for="(header_column, headerIdx) in headers"
                :id="`gutter-col-${header_column.id}`"
                :key="header_column.id"
                :class="{
                  'column-active-top': rubric.state.currentlyEditingLine === header_column,
                  'is-available-target-col': rubric.isAvailableTargetMatch('col'),
                  'is-selected-col': rubric.isSelectedColumn(headerIdx),
                  'is-selected-col-last': rubric.isSelectedColumnLast(),
                }"
                class="gutter gutter-col"
                data-cell-type="col"
                :data-header-id="header_column.id"
                :data-header-idx="headerIdx"
                :data-droppable="true"
                scope="col"
                @dragover.prevent="rubric.dragOverEventCol($event, headerIdx)"
                @drop="rubric.handleDrop">
                <button
                  v-show="rubric.state.currentlyEditingLine !== header_column"
                  class="c-no-button c-no-button--gutter"
                  type="button"
                  aria-live="polite"
                  aria-atomic="true"
                  @click="rubric.startEditingLine(header_column)"
                  @mouseover="rubric.startEditingLine(header_column)">
                  <span class="u-screen-reader-only">Click to add or remove a column</span>
                </button>
                <div
                  v-show="rubric.state.currentlyEditingLine === header_column"
                  aria-live="polite"
                  aria-atomic="true"
                  @mouseleave="rubric.stopEditingLine()">
                  <span class="u-screen-reader-only">Choose an action</span>
                  <!-- eslint-disable vue/no-v-html -->
                  <div class="l-line  drag-and-drop-wrapper-col">
                    <span
                      class="drag-and-drop__icon"
                      draggable="true"
                      :data-header-id="header_column.id"
                      :data-header-idx="headerIdx"
                      data-cell-type="col"
                      @dragstart="rubric.dragStartEvent($event, 'col')"
                      @dragend="handleDragEnd"
                      v-html="icons.dragAndDrop" />
                  </div>
                  <div
                    class="l-line  l-line--justify  gutter-actions">
                    <!-- eslint-enable vue/no-v-html -->
                    <!-- eslint-disable vue/no-v-html -->
                    <tippy :content="tooltipAddColMsg('left')" placement="bottom-start">
                      <a
                        href="javascript://"
                        :class="{ 'is-disabled' : !rubric.canAddColumns }"
                        class="gutter-actions__icon"
                        :aria-label="tooltipAddColMsg('left')"
                        @click="rubric.addNewColumn(headerIdx)"
                        v-html="icons.add" />
                    </tippy>
                    <tippy :content="tooltipRemoveMsg('column')" placement="bottom">
                      <a
                        href="javascript://"
                        :class="{ 'is-disabled' : !rubric.canRemoveColumns }"
                        class="gutter-actions__icon"
                        :aria-label="tooltipRemoveMsg('column')"
                        @click=" rubric.deleteColumn(headerIdx); scrollToTop();"
                        v-html="icons.delete" />
                    </tippy>
                    <tippy :content="tooltipAddColMsg('right')" placement="bottom-end">
                      <a
                        href="javascript://"
                        :class="{ 'is-disabled' : !rubric.canAddColumns }"
                        class="gutter-actions__icon"
                        :aria-label="tooltipAddColMsg('right')"
                        @click="rubric.addNewColumn(headerIdx + 1)"
                        v-html="icons.add" />
                    <!-- eslint-enable vue/no-v-html -->
                    </tippy>
                    <span
                      v-if="rubric.state.assistiveColumn"
                      aria-live="polite"
                      aria-atomic="true"
                      class="u-screen-reader-only">{{ rubric.state.message }}</span>
                  </div>
                </div>
              </th>
            </tr>
            <!-- editable column header -->
          </thead>
          <tbody>
            <tr class="c-header-row  c-header-row--title">
              <td
                :data-criteria-idx="0"
                :data-header-idx="0"
                :data-header-id="-1"
                data-cell-type="mix"
                data-droppable="true"
                class="gutter-no-actions"
                @dragover.prevent=""
                @drop.prevent="rubric.handleDrop" />
              <th
                class="title-header"
                :data-criteria-idx="0"
                :data-header-idx="0"
                :data-header-id="1"
                data-cell-type="mix"
                :data-droppable="true"
                @dragover.prevent=""
                @drop.prevent="rubric.handleDrop" />
              <th
                v-for="(header_column, header_column_idx) in headers"
                :id="`header-${header_column.id}`"
                :key="header_column.id"
                :class="{
                  'column-active-ctr': rubric.state.currentlyEditingLine === header_column,
                  'is-available-target-col': rubric.isAvailableTargetMatch('col'),
                  'is-selected-col': rubric.isSelectedColumn(header_column_idx),
                  'is-selected-col-last': rubric.isSelectedColumnLast(),
                }"
                class="column-criteria"
                :data-header-idx="header_column_idx"
                :data-header-id="header_column.id"
                scope="col"
                data-cell-type="col"
                :data-droppable="true"
                @dragover.prevent="rubric.dragOverEventCol($event, header_column_idx)"
                @drop="rubric.handleDrop">
                <div class="header-container">
                  <span class="header-text">
                    {{ header_column.label }}
                  </span>
                  <!-- eslint-disable vue/no-v-html -->
                  <a
                    href="javascript://"
                    @click="rubric.startEditingHeader(header_column)"
                    v-html="icons.edit" />
                  <!-- eslint-enable vue/no-v-html -->
                </div>
              </th>
            </tr>
            <tr
              v-for="(criterion, idxCriterion) in rubric.content.criterias"
              :key="criterion.Criteria.title"
              class="c-row  c-row--with-gutter"
              :data-criteria-row="true">
              <!-- editable row header -->
              <th
                :id="`gutter-row-${idxCriterion}`"
                scope="row"
                class="gutter  gutter-row"
                :class="{
                  'row-active-lt': rubric.state.currentlyEditingLine === criterion,
                  'is-available-target-row': rubric.isAvailableTargetMatch('row'),
                  'is-selected-row': rubric.isSelectedRow(idxCriterion),
                  'is-selected-row-last': rubric.isSelectedRowLast(),
                }"
                data-cell-type="row"
                :data-criteria-idx="idxCriterion"
                :data-droppable="true"
                @dragend.prevent="rubric.dragLeaveEvent($event)"
                @dragover.prevent="rubric.dragOverEventRow($event, idxCriterion)"
                @drop="rubric.handleDrop">
                <button
                  v-show="rubric.state.currentlyEditingLine !== criterion"
                  class="c-no-button c-no-button--gutter"
                  type="button"
                  @click="rubric.startEditingLine(criterion)"
                  @mouseover="rubric.startEditingLine(criterion)">
                  <span class="u-screen-reader-only">Click to add or remove a row</span>
                </button>
                <div
                  v-show="rubric.state.currentlyEditingLine === criterion"
                  aria-live="polite"
                  aria-atomic="true"
                  class="gutter-actions-wrapper"
                  @mouseleave="rubric.stopEditingLine()">
                  <span class="u-screen-reader-only">Choose an action</span>
                  <div class="l-line  drag-and-drop-wrapper-row">
                    <!-- eslint-disable vue/no-v-html -->
                    <span
                      class="drag-and-drop__icon"
                      draggable="true"
                      :data-criteria-idx="idxCriterion"
                      data-cell-type="row"
                      @dragstart="rubric.dragStartEvent($event, 'row')"
                      @dragend="handleDragEnd"
                      v-html="icons.dragAndDrop" />
                    <!-- eslint-disable vue/no-v-html -->
                  </div>
                  <div
                    class="l-line  l-line--justify  gutter-actions">
                    <!-- eslint-disable vue/no-v-html -->
                    <tippy :content="tooltipAddRowMsg('above')" placement="bottom-start">
                      <a
                        href="javascript://"
                        :class="{ 'is-disabled' : !rubric.canAddRows }"
                        class="gutter-actions__icon"
                        :aria-label="tooltipAddRowMsg('above')"
                        @click="rubric.addNewRow(idxCriterion)"
                        v-html="icons.add" />
                    </tippy>
                    <tippy :content="tooltipRemoveMsg('row')" placement="bottom-start">
                      <a
                        href="javascript://"
                        :class="{ 'is-disabled' : !rubric.canRemoveRows }"
                        class="gutter-actions__icon"
                        :aria-label="tooltipRemoveMsg('row')"
                        @click="rubric.deleteRow(idxCriterion); scrollToTop();"
                        v-html="icons.delete" />
                    </tippy>
                    <tippy :content="tooltipAddRowMsg('below')" placement="bottom-start">
                      <a
                        href="javascript://"
                        :class="{ 'is-disabled' : !rubric.canAddRows }"
                        class="gutter-actions__icon"
                        :aria-label="tooltipAddRowMsg('below')"
                        @click="rubric.addNewRow(idxCriterion + 1)"
                        v-html="icons.add" />
                    </tippy>
                    <!-- eslint-enable vue/no-v-html -->
                    <span
                      v-if="rubric.state.assistiveRow"
                      aria-live="polite"
                      aria-atomic="true"
                      class="u-screen-reader-only">{{ rubric.state.message }}</span>
                  </div>
                </div>
              </th>
              <!-- editable row header -->
              <th
                :id="`criterion-${idxCriterion}`"
                scope="row"
                :class="
                  { 'row-active-mid': rubric.state.currentlyEditingLine === criterion,
                    'is-selected-row': rubric.isSelectedRow(idxCriterion),
                    'is-selected-row-last': rubric.isSelectedRowLast(),
                    'is-available-target-row': rubric.isAvailableTargetMatch('row'),
                  }"
                class="criterion-row  u-txt-bold  u-txt-top"
                data-cell-type="row"
                :data-criteria-idx="idxCriterion"
                :data-droppable="true"
                @dragend.prevent="rubric.dragLeaveEvent($event)"
                @dragover.prevent="rubric.dragOverEventRow($event, idxCriterion)"
                @drop="rubric.handleDrop">
                <div class="header-container">
                  <span class="header-text">
                    {{ criterion.Criteria.title }}
                  </span>
                  <!-- eslint-disable vue/no-v-html -->
                  <a
                    href="javascript://"
                    @click="rubric.startEditingCriterion(criterion.Criteria)"
                    v-html="icons.edit" />
                  <!-- eslint-enable vue/no-v-html -->
                </div>
              </th>
              <td
                v-for="(performance, idx) in criterion.Criteria.performances"
                :key="performance.header_id"
                class="column-performance"
                :class="[
                  `${cellColumnClass(idx, idxCriterion)} ${cellRowClass(criterion, idx)}`,
                  {
                    'is-selected-col': rubric.isSelectedColumn(idx),
                    'is-selected-col-last': rubric.isSelectedColumnLast(),
                    'is-selected-row': rubric.isSelectedRow(idxCriterion),
                    'is-selected-row-last': rubric.isSelectedRowLast(),
                    'is-available-target-col': rubric.isAvailableTargetMatch('col'),
                    'is-available-target-row': rubric.isAvailableTargetMatch('row'),
                  }
                ]"
                :data-header-id="headers[idx].id"
                :data-header-idx="idx"
                :data-criteria-idx="idxCriterion"
                :headers="`header-${headers[idx].id} gutter-col-${headers[idx].id}
                  gutter-row-${idxCriterion} criterion-${idxCriterion}`">
                <!-- eslint-disable vue/no-v-html -->
                <span v-html="performance.description" />
                <!-- eslint-enable vue/no-v-html -->
                <div>
                  <span class="u-txt-bold">
                    Points: {{ performance.score }}
                  </span>
                  <!-- eslint-disable vue/no-v-html -->
                  <a
                    href="javascript://"
                    @click="rubric.startEditingPerformance(performance)"
                    v-html="icons.edit" />
                  <!-- eslint-enable vue/no-v-html -->
                </div>
              </td>
            </tr>
          </tbody>
        </table>
        <GhostColumn
          v-if="rubric.selectedCellData.type == 'col'"
          :selectedCellData="rubric.selectedCellData" />
        <GhostRow
          v-if="rubric.selectedCellData.type == 'row'"
          :selectedCellData="rubric.selectedCellData" />
        <div class="rubric-form-footer-container">
          <label>Total points: {{ rubric.totalPoints }}</label>
          <SaveActivityForm
            :activityId="activityId"
            :isDev="false"
            :returnUrl="returnUrl"
            :submitUrl="submitUrl" />
        </div>
      </div>
    </div>
    <BasicDialog
      v-if="rubric.headerToEdit"
      :isConfirmationDialog="false"
      :isModal="true"
      title="Edit Header"
      @close-dialog="rubric.cancelEditingHeader">
      <template #body>
        <div
          class="c-form-item"
          :class="{ 'c-form-item--error' : rubric.validationError.cellHeader.length > 0}">
          <label class="c-form-item__label" for="headerLabel">Label</label>
          <input
            id="headerLabel"
            v-model="rubric.unsavedHeader.label"
            class="c-form-item__input"
            type="text"
            size="50">
          <ErrorMessage
            cellValidator="cellHeader" />
        </div>

        <ErrorSummary />
      </template>
      <template #footer>
        <div>
          <StandardButton
            class="u-mar-rt-8  js-dialog-a11y__first-focus-elm"
            @click="rubric.cancelEditingHeader">
            Cancel
          </StandardButton>
          <StandardButton
            variant="primary"
            class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
            @click="rubric.saveHeaderEdits">
            Save
          </StandardButton>
        </div>
      </template>
    </BasicDialog>
    <BasicDialog
      v-if="rubric.criterionToEdit"
      :isConfirmationDialog="false"
      :isModal="true"
      title="Edit Criterion"
      @close-dialog="rubric.cancelEditingCriterion">
      <template #body>
        <div
          class="c-form-item"
          :class="{ 'c-form-item--error' : rubric.validationError.cellCriterionTitle.length > 0}">
          <label class="c-form-item__label" for="criterionTitle">Title</label>
          <input
            id="criterionTitle"
            v-model="rubric.unsavedCriterion.title"
            class="c-form-item__input"
            type="text"
            size="50">
          <ErrorMessage
            cellValidator="cellCriterionTitle" />
        </div>

        <ErrorSummary />
      </template>
      <template #footer>
        <div>
          <StandardButton
            class="u-mar-rt-8  js-dialog-a11y__first-focus-elm"
            @click="rubric.cancelEditingCriterion">
            Cancel
          </StandardButton>
          <StandardButton
            variant="primary"
            class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
            @click="rubric.saveCriterionEdits">
            Save
          </StandardButton>
        </div>
      </template>
    </BasicDialog>
    <BasicDialog
      v-if="rubric.performanceToEdit"
      :isConfirmationDialog="false"
      :isModal="true"
      title="Edit Description"
      @close-dialog="rubric.cancelEditingPerformance">
      <template #body>
        <div
          class="c-form-item">
          <label class="c-form-item__label" for="cellDescription">Description</label>
          <froala
            id="cellDescription"
            v-model="rubric.unsavedPerformance.description"
            class="c-form-item__textarea"
            :tag="'textarea'"
            :config="froalaConfig" />
          <ErrorMessage
            cellValidator="cellDescription" />
        </div>

        <div
          class="c-form-item"
          :class="{ 'c-form-item--error' : rubric.validationError.cellScore.length > 0}">
          <label class="c-form-item__label" for="cellScore">Points</label>
          <input
            id="cellScore"
            v-model="rubric.unsavedPerformance.score"
            class="c-form-item__input"
            type="number"
            size="4">
          <ErrorMessage
            cellValidator="cellScore" />
        </div>

        <ErrorSummary />
      </template>
      <template #footer>
        <div>
          <StandardButton
            class="u-mar-rt-8  js-dialog-a11y__first-focus-elm"
            @click="rubric.cancelEditingPerformance">
            Cancel
          </StandardButton>
          <StandardButton
            variant="primary"
            class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
            @click="rubric.savePerformanceEdits">
            Save
          </StandardButton>
        </div>
      </template>
    </BasicDialog>
  </div>
</template>

<script setup>
  import { StandardButton } from 'music';
  import { Tippy } from 'vue-tippy';
  import BasicDialog from
  'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';
  import { reactive, provide, readonly, computed } from 'vue';
  import { metaTagContent } from 'shared/utils';
  import GhostRow from './GhostRow.vue';
  import GhostColumn from './GhostColumn.vue';
  import ErrorMessage from './ErrorMessage.vue';
  import ErrorSummary from './ErrorSummary.vue';
  import SaveActivityForm from './SaveRubricForm';
  import useRubricEditingStore from './use_rubric_editing_store';

  /**
   * Loads HTML for rendering icons from x-template nodes.
   * @return {Object.<string, string>} The keys are the names of the icons,
   * and the values are strings with the HTML that renders the icon.
   */
  function populateIcons() {
    const iconDivs = {
      'add': 'music_icon_add',
      'delete': 'music_icon_delete',
      'dragAndDrop': 'icon_drag_and_drop',
      'edit': 'music_icon_edit',
      'mediumSave': 'music_icon_medium_save',
    };

    return (
      Object.keys(iconDivs).reduce(
        (memo, key) => {
          memo[key] = document.getElementById(iconDivs[key])?.innerHTML;
          return memo;
        },
        {}
      )
    );
  }

  const props = defineProps(
    {
      activityId: { default: '', type: String },
      draft: { default: 'true', type: String },
      lessonId: { required: true, type: String },
      returnUrl: { required: true, type: String },
      rubricJson: { required: true, type: String },
      startUnit: { required: true, type: String },
      strandId: { required: true, type: String },
      submitUrl: { required: true, type: String },
    }
  );

  const activity = reactive(
    {
      csrfToken: metaTagContent('csrf-token'),
      state: {
        draft: props.draft,
      },
    }
  );

  const rubric = useRubricEditingStore();
  rubric.init(
    {
      lessonId: props.lessonId,
      rubricJson: props.rubricJson,
      startUnit: props.startUnit,
      strandId: props.strandId,
    }
  );

  const icons = populateIcons();
  const froalaConfig = {
    attribution: false, // Hide "Powered by Froala" banner
    charCounterCount: false, // Hide character count
    heightMin: 200,
    width: 500,
    htmlRemoveTags: ['script'],
    htmlAllowedTags: ['p', 'br', 'strong', 'em', 'ul', 'ol', 'li'],
    htmlExecuteScripts: false,
    events: {
      blur: function() {
        this.html.cleanEmptyTags();
        this.clean.tables();
        this.clean.lists();
      },
      contentChanged: function() {
        this.html.cleanEmptyTags();
        this.clean.tables();
        this.clean.lists();
      },
    },
    key: 'QFF4nB16B7B7C4A3G4F3fLUQZa1ASFe1EFRNc1He1BCCQDUHnD5D4B3H4C3D7E5C2C4D4==',
    toolbarButtons: {
      moreText: {
        buttons: [
          'bold',
          'italic',
        ],
        buttonsVisible: 2,
      },
      moreParagraph: {
        buttons: [
          'formatMaestroOL',
          'formatMaestroUL',
        ],
        buttonsVisible: 2,
      },
      moreMisc: {
        buttons: ['undo', 'redo'],
      },
    },
    toolbarSticky: false,
  };

  const headers = rubric.headerColumns;

  /** this is to define the width of the table,
   * and the width of the criteria columns, gutter header for CSS. */
  const tableWidth = 60;
  const gutterWidth = 1.25;
  const criteronWidth = 11.5;

  const columnWidth = computed(() => {
    const performanceWidth = tableWidth - gutterWidth - criteronWidth - 1;
    return performanceWidth / rubric.headerColumns.length;
  });

  /**
   * returns add column icon tooltip message.
   * @param {string} position - icon position right/left
   * @return {string} - Tooltip message for add icon.
   */
  function tooltipAddColMsg(position) {
    if (rubric.canAddColumns) {
      return `Add a column on the ${position}`;
    } else {
      return 'You have reached the maximum number of columns allowed';
    }
  }

  /**
   * returns add row icon tooltip message.
   * @param {string} position - icon position above/below
   * @return {string} - Tooltip message for add icon.
   */
  function tooltipAddRowMsg(position) {
    if (rubric.canAddRows) {
      return `Add a row ${position}`;
    } else {
      return 'You have reached the maximum number of rows allowed';
    }
  }

  /**
   * returns remove icon tooltip message.
   * @param {string} cellType - cell type row/column
   * @param {string} position - icon position right/left/above/below
   * @return {string} - Tooltip message for remove icon.
   */
  function tooltipRemoveMsg(cellType) {
    const minCondition = cellType == 'row' ? rubric.canRemoveRows : rubric.canRemoveColumns;
    if (minCondition) {
      return `Delete this ${cellType}`;
    } else {
      return `You have reached the minimum number of ${cellType}s allowed`;
    }
  }

  /**
   * Return cell class to highight column borders.
   * @param {number} headerIdx
   * @param {number} criterionIdx
   * @return {string}
   */
  function cellColumnClass(headerIdx, criterionIdx) {
    let columnClass = '';
    if (rubric.state.currentlyEditingLine === headers[headerIdx]) {
      if (criterionIdx != rubric.criterias.length - 1) {
        columnClass = 'column-active-ctr';
      } else if (criterionIdx == rubric.criterias.length - 1) {
        columnClass = 'column-active-bot';
      }
    }
    return columnClass;
  }

  /**
   * Return cell class to highight row borders.
   * @param {Object} criterion
   * @param {number} performanceIdx
   * @return {string}
   */
  function cellRowClass(criterion, performanceIdx) {
    let rowClass = '';
    if (rubric.state.currentlyEditingLine === criterion) {
      if (performanceIdx != criterion.Criteria.performances.length - 1) {
        rowClass = 'row-active-mid';
      } else if (performanceIdx == criterion.Criteria.performances.length - 1) {
        rowClass = 'row-active-rt';
      }
    }
    return rowClass;
  }

  /**
   * Move scroll to Top for showing the banner alert.
   */
  function scrollToTop() {
    if (rubric.showBannerAlert) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  }

  provide('rubric', rubric);
  provide('icons', readonly(icons));
  provide('activity', activity);

  /**
   * Clean selected and available target and clean dragstate object.
   * @param {Event} event - dragend event.
   */
  function handleDragEnd(event) {
    rubric.clearDragState();
    rubric.cleardragAndDropElms();
  }
</script>

<style lang="scss" scoped="module">
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  .ns-rubrics-preview .c-activity-rubric.rubric-editing-container {
    margin-top: 0;
  }

  .c-rubric-table--edit {
    --col-width: v-bind(`${columnWidth}rem`);
    --col-gutter-width: v-bind(`${gutterWidth}rem`);
    --criterion-width: v-bind(`${criteronWidth}rem`);
    --table-width: v-bind(`${tableWidth}rem`);

    max-width: var(--table-width)
  }

  .column-criteria,
  .gutter-col,
  .column-performance {
    &.is-available-target-col,
    &.is-available-target {
      border-left: 0.25rem dashed $gray-c;
      margin: 0 0.5rem;

      &:last-child {
        border-right: 0.25rem dashed $gray-c;
      }
    }

    &.is-selected-col {
      border-left-color: $blue;
    }

    &:last-child {
      &.is-selected-col-last {
        border-right-color: $blue;
      }
    }
  }

  .gutter-row,
  .criterion-row,
  .column-performance {
    &.is-available-target-row,
    &.is-available-target {
      border-top: 0.25rem dashed $gray-c;
      margin: 0 0.5rem;
    }

    &.is-selected-row {
      border-top-color: $blue;
    }
  }


  .c-header-row--gutter,
  .c-row--with-gutter {
    .gutter-no-actions,
    .gutter {
      background-color: var(--white, $white);
      padding: 0;
      height: rpx(20);
      max-height: rpx(20);
      position: relative;
    }

    .gutter-actions {
      width: 100%;
      height: 100%;
      line-height: normal;
      padding: 0 0.25rem;

      span:has(.gutter-actions__icon) {
        margin-right: 0;
      }
    }
  }

  .c-row--with-gutter:last-child {
    .gutter-row,
    .criterion-row,
    .column-performance {
      &.is-available-target-row,
      &.is-available-target {
        border-bottom: 0.25rem dashed $gray-c;
      }

      &.is-selected-row-last {
        border-bottom-color: $blue;
      }
    }
  }

  .drag-and-drop-wrapper-col {
    position: absolute;
    top: -22px;
    width: 100%;
    height: 100%;

    .drag-and-drop__icon {
      display: inline-block;
      margin: auto;

      :deep(.c-svg) {
        transform: rotate(90deg);
      }
    }
  }

  .drag-and-drop-wrapper-row {
    position: absolute;
    left: -22px;
    width: 100%;
    height: 100%;

    .drag-and-drop__icon {
      display: inline-block;
      margin: auto;
    }
  }

  th,
  td {
    &.column-active-top {
      border: rpx(1) $blue double;
      border-bottom: 0;
    }

    &.column-active-ctr {
      border-right: rpx(1) $blue double;
      border-left: rpx(1) $blue double;
    }

    &.column-active-bot {
      border: rpx(1) $blue double;
      border-top: 0;
    }

    &.row-active-lt {
      border-bottom: rpx(1) $blue double;
      border-left: rpx(1) $blue double;
      border-top: rpx(1) $blue double;
    }

    &.row-active-mid {
      border-bottom: rpx(1) $blue double;
      border-top: rpx(1) $blue double;
    }

    &.row-active-rt {
      border-bottom: rpx(1) $blue double;
      border-right: rpx(1) $blue double;
      border-top: rpx(1) $blue double;
    }
  }

  .column-criteria {
    width: var(--col-width);
  }

  .header-container {
    display: flex;

    .header-text {
      width: fit-content;
      margin-right: 0.5rem;
    }
  }

 .c-no-button--gutter {
    display: block;
    width: 100%;
    height: 100%;
  }

  .c-header-row--title {
    &:first-child {
      background-color: var(--white, $white);
    }

    .title-header {
      width: var(--criterion-width);
    }
  }

  .gutter-row {
    width: var(--col-gutter-width);
    max-width: var(--col-gutter-width);
    height: 0;
    padding: 0;

    .gutter-actions-wrapper {
      width: 100%;
      height: 100%;
    }

    .gutter-actions {
      flex-direction: column;
      padding: 0 0.25rem;

      span:has(.gutter-actions__icon) {
        margin-right: 0;
      }
    }
  }

  .rubric-form-footer-container {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
  }

  .c-rubrics-alert-banner {
    display: flex;
    justify-content: center;
    min-height: 6.5rem;

    &__container {
      max-width: 30rem;
      margin-top: mod(1);
      border-radius: mod(0.625);
      padding: mod(0.75);
      border: rpx(1) solid $light-blue;
      background-color: tint-saturate($light-blue, 90);
    }

    &__close-wrapper {
      text-align: right;
    }
  }
</style>
