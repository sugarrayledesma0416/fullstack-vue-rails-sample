import { defineStore } from 'pinia';
import { isEmpty, maxInArray } from 'shared/utils';
import assert from 'assert';

/**
 * @typeDef RubricData
 * @property {string} lessonId - ID of ToC lesson to return to
 * @property {string} rubricJson - JSON representation of the
 * rubric data from the ruby activity content object
 * @property {string} startUnit - Rank of ToC unit to return to
 * @property {string} strandId - ID of ToC strand to return to
 */

/**
 * @return {Function} A Pinia `useStore` function, which retrieves the Pinia
 * store, defining it if necessary.
 */
const useRubricEditingStore = defineStore(
  'rubricEditingStore',
  {
    state: () => (
      {
        content: {},
        initialJson: '',
        criterionToEdit: null,
        currentHeaderId: null,
        currentRowSelected: null,
        currentRowSelectedPos: null,
        currentColumnSelected: null,
        currentColumnSelectedPos: null,
        currentAvailableTarget: null,
        criteriaTitle: null,
        unsavedCriterion: {},
        headerToEdit: null,
        lastAddedColumnNumber: 1,
        lastAddedRowNumber: 1,
        lastDataDeleted: {},
        lessonId: '',
        // TODO: This is consumed by the Save/Exit forms. Needs to
        // be implemented as an action.
        isValid: () => true,
        unsavedHeader: {},
        performanceToEdit: null,
        maxColumns: 5,
        maxRows: 12,
        selectedCellData: { type: '' },
        startUnit: '',
        state: {
          currentlyEditingLine: null,
          message: null,
          assistiveColumn: null,
          assistiveRow: null,
        },
        strandId: '',
        showBannerAlert: false,
        unsavedPerformance: {},
        validationError: {
          cellCriterionTitle: [],
          cellDescription: [],
          cellHeader: [],
          cellScore: [],
        },
      }
    ),
    getters: {
      hasChanges() {
        const initialObject = JSON.parse(this.initialJson);
        // deepStrictEqual fails without this hack because this.content
        // isn't an object but rather a Proxy.
        const currentContent = JSON.parse(JSON.stringify(this.content));

        // deepStrictEqual will consider objects to be equal if their keys
        // and values are equal.
        // Unlike with a regular equality check, it won't return false if a
        // value points to a different object reference.
        // Unlike comparing by using JSON.stringify, it won't return false if
        // two objects have the same values but the keys are in a different
        // order.
        // e.g. { a: 1, b: 2 } is considered equal to { b: 2, a: 1 }

        try {
          assert.deepStrictEqual(currentContent, initialObject);
        } catch (error) {
          if (error.name === 'AssertionError') {
            return true;
          } else {
            throw (error);
          }
        }
        return false;
      },
      errorValidatorCount() {
        return Object.values(this.validationError).filter((value) => value.length > 0).length;
      },
      totalPoints() {
        let totalPoints = 0;
        this.content.criterias.forEach(
          (criterion) => {
            totalPoints += maxInArray(criterion.Criteria.performances.map((item) => item.score));
          });
        return totalPoints;
      },
      hasDuplicatedTitle() {
        const otherCriteria = this.content.criterias.filter(
          (criterion) => criterion.Criteria != this.criterionToEdit
        );
        return otherCriteria.some(
          (criterion) => {
            const savedTitle = criterion.Criteria.title.toLowerCase();
            const unsavedTitle = this.unsavedCriterion.title.toLowerCase();
            return savedTitle === unsavedTitle;
          }
        );
      },
      canAddColumns() {
        return this.headerColumns.length < this.maxColumns;
      },
      canAddRows() {
        return this.criterias.length < this.maxRows;
      },
      canRemoveColumns() {
        return this.headerColumns.length > 1;
      },
      canRemoveRows() {
        return this.criterias.length > 1;
      },
      /**
       * @private
       * @return {Object}
       */
      headerColumns() {
        return this.content.header_row.HeaderRow.header_columns;
      },
      /**
       * @private
       * @return {Object}
       */
      criterias() {
        return this.content.criterias;
      },
      /**
       * @private
       * Returns a new performance object.
       * @return {Object} - new performance to add.
       */
      newPerformance() {
        return {
          description: 'Edit description and points',
          header_id: `${this.currentHeaderId}`,
          score: 1,
        };
      },
      /**
       * @private
       * Returns a new header object.
       * @return {Object} - new header to add.
       */
      newHeader() {
        return {
          id: `${this.currentHeaderId}`,
          label: `New column ${this.lastAddedColumnNumber}`,
        };
      },
      /**
       * @private
       * Returns a new criteria object.
       * @return {Object} - new criteria to add.
       */
      newCriteria() {
        const criteria = {
          Criteria: {
            title: `New row ${this.lastAddedRowNumber}`,
            performances: [],
          },
        };
        this.criteriaTitle = this.lastAddedRowNumber;
        this.headerColumns.map((headerColumn) => {
          this.currentHeaderId = headerColumn.id;
          criteria.Criteria.performances.push(this.newPerformance);
        });
        return criteria;
      },
    },
    actions: {
      addNewColumn(idxColToAdd) {
        if (!this.canAddColumns) return;
        const maxId = maxInArray(this.headerColumns.map((column) => parseInt(column.id))) + 1;

        this.currentHeaderId = maxId;
        this.headerColumns.splice(idxColToAdd, 0, this.newHeader);
        this.criterias.map((criterion) => {
          this.criteriaTitle = criterion.Criteria.title;
          criterion.Criteria.performances.splice(idxColToAdd, 0, { ...this.newPerformance });
        });
        this.criteriaTitle = null;
        this.lastAddedColumnNumber++;
        this.state.message = 'A new column was added';
        this.state.assistiveColumn = true;
        if (this.showBannerAlert && !this.canAddColumns) {
          this.showBannerAlert = false;
          this.lastDataDeleted = {};
        }
      },
      addNewRow(idxRowToAdd) {
        if (!this.canAddRows) return;

        this.criterias.splice(idxRowToAdd, 0, this.newCriteria);
        this.criteriaTitle = null;
        this.lastAddedRowNumber++;
        this.state.message = 'A new row was added';
        this.state.assistiveRow = true;
        if (this.showBannerAlert && !this.canAddRows) {
          this.showBannerAlert = false;
          this.lastDataDeleted = {};
        }
      },
      deleteRow(criteriaIdx) {
        if (!this.canRemoveRows) return;
        this.lastDataDeleted = {
          performances: [...this.criterias],
        };
        this.criterias.splice(criteriaIdx, 1);
        this.state.message = 'Row delete';
        this.state.assistiveRow = true;
        this.showBannerAlert = true;
      },
      deleteColumn(headerIdx) {
        if (!this.canRemoveColumns) return;
        this.lastDataDeleted = {
          headerId: headerIdx,
          lastHeaderRemoved: this.headerColumns[headerIdx],
          performances: [],
        };
        this.criterias.map((criterion) => {
          this.lastDataDeleted.performances.push(criterion.Criteria.performances[headerIdx]);
          criterion.Criteria.performances.splice(headerIdx, 1);
        });
        this.headerColumns.splice(headerIdx, 1);
        this.state.message = 'Column delete';
        this.state.assistiveColumn = true;
        this.showBannerAlert = true;
      },
      cancelEditingCriterion() {
        this.criterionToEdit = null;
        this.unsavedCriterion = {};
        this.validationError = {
          cellCriterionTitle: [],
          cellDescription: [],
          cellHeader: [],
          cellScore: [],
        };
      },
      cancelEditingHeader() {
        this.headerToEdit = null;
        this.unsavedHeader = {};
        this.validationError = {
          cellCriterionTitle: [],
          cellDescription: [],
          cellHeader: [],
          cellScore: [],
        };
      },
      cancelEditingPerformance() {
        this.performanceToEdit = null;
        this.unsavedPerformance = {};
        this.validationError = {
          cellCriterionTitle: [],
          cellDescription: [],
          cellHeader: [],
          cellScore: [],
        };
      },
      /**
       * @param {RubricData} initialData
       */
      init(initialData) {
        this.initialJson = initialData.rubricJson;
        this.content = JSON.parse(this.initialJson);
        this.lessonId = initialData.lessonId;
        this.startUnit = initialData.startUnit;
        this.strandId = initialData.strandId;
        this.validateNewRow();
        this.validateNewCol();
      },
      validateNewRow() {
        /* validates if there are rows with the default
          new row name and continues with the next index. */
        const titlesWithDefaultName = this.criterias.map((criteria) => {
          const title = criteria.Criteria.title;
          if (title.startsWith('New row')) {
            return parseInt(title.replace(/\D/g, ''));
          }
          return null;
        }).filter((title) => Number.isInteger(title));
        if (titlesWithDefaultName.length > 0) {
          this.lastAddedRowNumber = Math.max(...titlesWithDefaultName) + 1;
        }
      },
      validateNewCol() {
        /* validates if there are columns with the default
          new column name and continues with the next index. */
        const headersWithDefaultName = this.headerColumns.map((header) => {
          const label = header.label;
          if (label.startsWith('New column')) {
            return parseInt(label.replace(/\D/g, ''));
          }
          return null;
        }).filter((title) => Number.isInteger(title));
        if (headersWithDefaultName.length > 0) {
          this.lastAddedColumnNumber = Math.max(...headersWithDefaultName) + 1;
        }
      },
      saveCriterionEdits() {
        this.validationError = {
          cellCriterionTitle: [],
          cellDescription: [],
          cellHeader: [],
          cellScore: [],
        };
        if (isEmpty(this.unsavedCriterion.title)) {
          this.validationError.cellCriterionTitle.push('Title cannot be blank');
        } else if (this.hasDuplicatedTitle) {
          this.validationError.cellCriterionTitle.push('Title must be unique');
        }

        if (this.errorValidatorCount > 0) return;

        this.criterionToEdit.title = this.unsavedCriterion.title;
        this.cancelEditingCriterion();
      },
      // TODO: Add unit tests
      saveHeaderEdits() {
        this.validationError = {
          cellCriterionTitle: [],
          cellDescription: [],
          cellHeader: [],
          cellScore: [],
        };
        if (isEmpty(this.unsavedHeader.label)) {
          this.validationError.cellHeader.push('Label cannot be blank');
        }

        if (this.errorValidatorCount > 0) return;

        this.headerToEdit.label = this.unsavedHeader.label;
        this.cancelEditingHeader();
      },
      savePerformanceEdits() {
        this.validationError = {
          cellCriterionTitle: [],
          cellDescription: [],
          cellHeader: [],
          cellScore: [],
        };
        if (isEmpty(this.unsavedPerformance.description)) {
          this.validationError.cellDescription.push('Description cannot be blank');
        }

        if (isEmpty(String(this.unsavedPerformance.score))) {
          this.validationError.cellScore.push('Points cannot be blank');
        } else if (isNaN(this.unsavedPerformance.score)) {
          this.validationError.cellScore.push('Points must be a number');
        } else if (this.unsavedPerformance.score <= 0) {
          this.validationError.cellScore.push('Points must be greater than zero');
        } else if (!Number.isInteger(parseFloat(this.unsavedPerformance.score))) {
          this.validationError.cellScore.push('Points must be a whole number');
        }

        if (this.errorValidatorCount > 0) return;

        this.performanceToEdit.description = this.unsavedPerformance.description;
        this.performanceToEdit.score = parseInt(this.unsavedPerformance.score);
        this.cancelEditingPerformance();
      },
      startEditingCriterion(criterionRef) {
        this.criterionToEdit = criterionRef;
        this.unsavedCriterion = { ...criterionRef };
      },
      startEditingHeader(headerRef) {
        this.headerToEdit = headerRef;
        this.unsavedHeader = { ...headerRef };
      },
      startEditingPerformance(performanceRef) {
        this.performanceToEdit = performanceRef;
        this.unsavedPerformance = { ...performanceRef };
      },
      startEditingLine(line) {
        this.state.currentlyEditingLine = line;
      },
      stopEditingLine() {
        this.state.currentlyEditingLine = null;
        this.state.message = '';
        this.state.assistiveColumn = false;
        this.state.assistiveRow = false;
      },
      undoLastRemovedData() {
        if (this.lastDataDeleted.hasOwnProperty('headerId')) {
          this.headerColumns
            .splice(this.lastDataDeleted.headerId, 0, this.lastDataDeleted.lastHeaderRemoved);
          this.criterias.map((criterion, index) => {
            criterion.Criteria.performances
              .splice(this.lastDataDeleted.headerId,
                0,
                this.lastDataDeleted.performances[index]);
            this.state.message = 'A column was recovered';
          });
        } else {
          this.content.criterias = this.lastDataDeleted.performances;
          this.state.message = 'A row was recovered';
        }
        this.lastDataDeleted = {};
        this.state.assistiveColumn = true;
        this.showBannerAlert = false;
      },
      dragStartEvent(event, targetType) {
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData(
          'Text',
          JSON.stringify(event.target.dataset)
        );
        if (event.target.dataset.cellType == 'row') {
          this.saveRowData(event);
        } else if (event.target.dataset.cellType == 'col') {
          this.saveColumnData(event);
        }

        this.selectedCellData.event = event;
        this.selectedCellData.type = event.target.dataset.cellType;
      },
      dragOverEventCol(event, headerIdx) {
        if (this.selectedCellData.type != 'col') return;

        event.dataTransfer.dropEffect = 'move';
        const target = this.targetContainer(event.target, 'droppable');
        const rect = target.getBoundingClientRect();

        if (event.clientX < (rect.left + rect.width / 2)) {
          this.currentColumnSelectedPos = 'left';
          this.currentColumnSelected = headerIdx;
        } else {
          this.currentColumnSelectedPos = 'right';
          this.currentColumnSelected = `${parseInt(headerIdx) + 1}`;
        }
        this.currentAvailableTarget = 'col';
      },
      dragOverEventRow(event, criteriaIdx) {
        if (this.selectedCellData.type != 'row') return;

        event.dataTransfer.dropEffect = 'move';
        const target = this.targetContainer(event.target, 'droppable');
        const rect = target.getBoundingClientRect();

        if (event.clientY < (rect.top + rect.height / 2)) {
          this.currentRowSelectedPos = 'above';
          this.currentRowSelected = criteriaIdx;
        } else {
          this.currentRowSelectedPos = 'below';
          this.currentRowSelected = `${parseInt(criteriaIdx) + 1}`;
        }

        this.currentAvailableTarget = 'row';
      },
      isAvailableTargetMatch(position) {
        return this.currentAvailableTarget == position;
      },
      saveRowData(event) {
        const criteriaIdx = event.target.dataset.criteriaIdx;
        this.selectedCellData.criteria = this.criterias[criteriaIdx];
      },
      saveColumnData(event) {
        const headerID = event.target.dataset.headerId;
        const performances = [];

        this.criterias.map((criterion) => {
          performances.push(criterion.Criteria.performances
            .find((performance) => performance.header_id == headerID));
        });

        this.selectedCellData.header = this.headerColumns.find((header) => header.id == headerID);
        this.selectedCellData.performances = performances;
      },
      isSelectedColumn(headerIdx) {
        return this.currentColumnSelectedPos != null ?
          this.currentColumnSelected == headerIdx : false;
      },
      isSelectedColumnLast() {
        return this.currentColumnSelected == this.headerColumns.length;
      },
      isSelectedRow(criterionIdx) {
        return this.currentRowSelectedPos != null ?
          this.currentRowSelected == criterionIdx : false;
      },
      isSelectedRowLast() {
        return this.currentRowSelected == this.criterias.length;
      },
      clearDragState() {
        this.selectedCellData.header = {};
        this.selectedCellData.performances = [];
        this.selectedCellData.event = {};
        this.selectedCellData.type = '';
        this.selectedCellData.criteria = {};
      },
      cleardragAndDropElms() {
        this.currentAvailableTarget = null;
        this.currentColumnSelected = null;
        this.currentColumnSelectedPos = null;
        this.currentRowSelected = null;
        this.currentRowSelectedPos = null;
      },
      targetContainer(elm, data) {
        if (elm.dataset[data]) {
          return elm;
        } else {
          return this.targetContainer(elm.parentElement, data);
        }
      },
      handleDrop(event) {
        this.clearDragState();
        this.cleardragAndDropElms();

        const draggableData = JSON.parse(event.dataTransfer.getData('Text'));
        const dropData = this.positionTargetData(event, draggableData);

        if (dropData.cellType != draggableData.cellType) return;

        if (dropData.cellType == 'row') {
          this.moveRow(draggableData, dropData);
        } else if (dropData.cellType == 'col') {
          this.moveColumn(draggableData, dropData);
        }
      },
      moveRow(draggableData, dropData) {
        const criteria = this.criterias[draggableData.criteriaIdx];
        this.criterias.splice(draggableData.criteriaIdx, 1);
        this.criterias.splice(dropData.criteriaIdx, 0, criteria);
      },
      moveColumn(draggableData, dropData) {
        const header = this.headerColumns[draggableData.headerIdx];
        const performances = [];

        this.headerColumns.splice(draggableData.headerIdx, 1);
        this.headerColumns.splice(dropData.headerIdx, 0, header);

        this.criterias.map((criterion, idx) => {
          const currentPerformances = criterion.Criteria.performances;
          performances.push(currentPerformances
            .find((performance) => performance.header_id == draggableData.headerId));
          currentPerformances.splice(draggableData.headerIdx, 1);
          currentPerformances.splice(dropData.headerIdx, 0, performances[idx]);
        });
      },
      /**
       * determines the coefficient to add to the headerIdx/criteriaIdx according to
       * whether the col/rows movement is ascending or descending
       * @param { Number} targetIdx - droppable target idx position
       * @param { Number} draggableIdx - draggable idx position
       * @return { Object } coefficient to add to headerIdx/criteriaIdx
       */
      positionCoefficients(targetIdx, draggableIdx) {
        const coefficients = {};
        if (targetIdx > draggableIdx) {
          coefficients.after = 0;
          coefficients.before = -1;
        } else if (targetIdx < draggableIdx) {
          coefficients.after = 1;
          coefficients.before = 0;
        } else {
          coefficients.after = 0;
          coefficients.before = 0;
        }
        return coefficients;
      },
      positionTargetData(event, draggableData) {
        const target = this.targetContainer(event.target, 'droppable');
        const targetData = target.dataset;
        const rect = target.getBoundingClientRect();
        const data = {
          target: target,
          cellType: targetData.cellType,
        };

        if (targetData.cellType == 'col') {
          const coefficientsIdx =
            this.positionCoefficients(targetData.headerIdx, draggableData.headerIdx);

          if (event.clientX < (rect.left + rect.width / 2)) {
            data.headerIdx = `${parseInt(targetData.headerIdx) + coefficientsIdx.before}`;
          } else {
            data.headerIdx = `${parseInt(targetData.headerIdx) + coefficientsIdx.after}`;
          }
        } else if (targetData.cellType == 'row') {
          const coefficientsIdx =
            this.positionCoefficients(targetData.criteriaIdx, draggableData.criteriaIdx);

          if (event.clientY < (rect.top + rect.height / 2)) {
            data.criteriaIdx =
              `${parseInt(targetData.criteriaIdx) + coefficientsIdx.before}`;
          } else {
            data.criteriaIdx =
              `${parseInt(targetData.criteriaIdx) + coefficientsIdx.after}`;
          }
        } else {
          data.cellType = draggableData.cellType;
          if (data.cellType == 'col') {
            data.headerIdx = targetData.headerIdx;
          } else {
            data.criteriaIdx = targetData.criteriaIdx;
          }
        }
        return data;
      },
    },
  }
);

export default useRubricEditingStore;
