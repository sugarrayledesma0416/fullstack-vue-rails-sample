import { defineStore } from 'pinia';
import * as ajaxUtils from 'shared/ajax_utils';
import AssignmentSetsCalendar
  from 'features/assignment_sets_calendar/models/assignment_sets_calendar';
import { dateFromCourseDateString } from 'shared/date_utils';
import { format } from 'date-fns';

/**
 * @typedef Activity
 * @property {number} activity_id
 * @property {string} activity_title - may contain html tags
 * @property {number|null} assignment_set_rank - activity rank in AssignmentSet,
 * is null when AssignmentSet hasn't been saved to the db
 * @property {string} lesson_name - may contain html tags
 * @property {string} strand_color - hex code
 * @property {string} strand_name - may contain html tags
 * @property {number} toc_rank - from assignment record, default rank if
 * no AssignmentSet with custom ranks has been created
 * @property {string} url - Url for opening preview of the activity
 */

/**
 * @typedef AssignmentSet
 * @property {string} due_date - in mysql database format: YYYY-MM-DD
 * @property {string} due_date_string - in format to be displayed: Monday Oct 8
 * @property {number|null} id - null if the set hasn't been saved to the db
 * @property {Array.<Activity>} activities - list of activities in the set
 */

/**
 * @typedef DropData
 * @property {number|string} entryIndex - Will be empty string if drop
 * event wasn't over an activity entry.
 * @property {string} position - either "above" or "below", ignored
 * when not dropping on an activity entry
 * @property {number} setDueDate - the due date of the set to insert into
 * @property {HtmlElement} target - event target
 */

const useAssignmentSetStore = defineStore(
  'store',
  {
    state: () => {
      return {
        assignmentSets: [],
        assignmentSetsDefaultOrder: [],
        calendar: {
          dateRange: {
            start: null,
            end: null,
          },
          attributes: [],
          courseStartDate: null,
          courseEndDate: null,
        },
        customOrderedCount: 0,
        dragState: {
          hoverPosition: '',
          originalSetDueDate: null,
          setDueDate: null,
          entryIndex: null,
        },
        errors: [],
        showCustomOrderConfirmation: false,
        showDefaultOrderConfirmation: false,
        showOnlyCustomOrderedAssignments: false,
        skipConfirmations: false,
        unconfirmedChange: null,
      };
    },
    getters: {
      csvExportUrl() {
        const startDate = this.dateToDatabaseDate(this.calendar.dateRange.start);
        const endDate = this.dateToDatabaseDate(this.calendar.dateRange.end);

        return `${this.csvUrl}?start_date=${startDate}&end_date=${endDate}`;
      },
    },
    actions: {
      /**
       * @param {Array.<AssignmentSet>} assignmentSets - The database persisted order
       * that assignments will present. This may be a custom order, or a default order.
       * @param {Array.<AssignmentSet>} assignmentSetsDefaultOrder - The database persisted order
       * that assignments would present if there is no custom order. This is used to reset a custom
       * ordered set back to default order.
       * @param {string} endpointUrl - base endpoint to which requests to
       * update an assignmentSet are sent
       * @param {string} csvUrl - url for requesting export in csv format
       * @param {string} courseStartDate - course start date in format "YYYY-MM-DD"
       * @param {string} courseEndDate - course end date in format "YYYY-MM-DD"
       */
      init(
        assignmentSets,
        assignmentSetsDefaultOrder,
        endpointUrl,
        csvUrl,
        courseStartDate,
        courseEndDate
      ) {
        this.assignmentSets = assignmentSets.map((assignmentSet) => {
          return {
            ...assignmentSet,
            dueDateAsDate: dateFromCourseDateString(assignmentSet.due_date),
          };
        });
        this.assignmentSets.forEach((set) => set.hasCustomOrder = !!set.id);

        this.assignmentSetsDefaultOrder = assignmentSetsDefaultOrder.map((assignmentSet) => {
          return {
            ...assignmentSet,
            dueDateAsDate: dateFromCourseDateString(assignmentSet.due_date),
          };
        });
        this.assignmentSetsDefaultOrder.forEach((set) => set.hasCustomOrder = false);

        this.endpointUrl = endpointUrl;
        this.csvUrl = csvUrl;
        this.calendar = new AssignmentSetsCalendar(courseStartDate, courseEndDate).forComponent();
      },
      /**
       * Hide the custom order confirmation dialog and reset the information
       * about the pending unconfirmed change to the assignment ranks.
       */
      cancelCustomOrderChange() {
        this.showCustomOrderConfirmation = false;
        this.skipConfirmations = false;
        this.unconfirmedChange = null;
      },
      /**
       * Hide the default order confirmation dialog and reset the
       * pending unconfirmed change to revert back to the original ranks.
       */
      cancelDefaultOrderChange() {
        this.showDefaultOrderConfirmation = false;
        this.unconfirmedChange = null;
      },
      /**
       * Persists the stashed unconfirmed change to the assignment ranks.
       */
      confirmCustomOrderChange() {
        const { set, currentIndex, newIndex } = this.unconfirmedChange;

        set.activities.splice(newIndex, 0, set.activities.splice(currentIndex, 1)[0]);
        this.assignActivityRankAttributes(set);
        this.saveSet(set);
      },
      /**
       * Persists the pending unconfirmed change to revert back to the
       * default order.
       */
      confirmDefaultOrderChange() {
        const { set } = this.unconfirmedChange;
        this.deleteSet(set);
      },
      /**
       * @param {Event} event - Dragover event
       */
      handleDragover(event) {
        const data = this.positionData(event);
        if (data.setDueDate) {
          this.dragState.hoverPosition = data.position;
          this.dragState.setDueDate = data.setDueDate;
          this.dragState.entryIndex = data.entryIndex;
        }
      },
      /**
       * @param {Event} event - dragEnd event
       */
      handleDragEnd(event) {
        event.target.classList.remove('activity-dragging');
        this.clearDragState();
      },
      /**
       * Store the data- attributes of the dragged element in the
       * dataTransfer interface.
       * @param {Object} activity - activity being dragged
       * @param {string} setDueDate - due date of set containing activity being dragged
       * @param {Event} event - dragStart event
       */
      handleDragStart(activity, setDueDate, event) {
        event.target.classList.add('activity-dragging');
        event.dataTransfer.setData(
          'Text',
          JSON.stringify(activity)
        );
        this.dragState.originalSetDueDate = setDueDate;
      },
      /**
       * @param {string} elmType - Either set or activity
       * @param {Event} event - Drop event
       */
      handleDrop(elmType, event) {
        const originalSetDueDate = this.dragState.originalSetDueDate;
        this.clearDragState();
        const dropData = this.positionData(event);
        const activityData = JSON.parse(event.dataTransfer.getData('Text'));
        this.insertDroppedActivity(dropData, activityData, originalSetDueDate);
      },
      /**
       * Display the confirmation dialog for switching back to default
       * order and store the pending unconfirmed change indicating which
       * set should be reverted on confirmation.
       * @param {AssignmentSet} set
       * @param {Event} event - Change event
       */
      handleSetMenuChange(set, event) {
        if (event.target.selectedIndex === 1) {
          this.unconfirmedChange = { set };
          this.showDefaultOrderConfirmation = true;
        }
      },

      inDateRange(assignmentSet) {
        return this.calendar.dateRange.start <= assignmentSet.dueDateAsDate &&
               assignmentSet.dueDateAsDate <= this.calendar.dateRange.end;
      },
      /**
       * @private
       * Assigns values in ascending order to the assignment_set_rank
       * attribute for each activity in the specified set.
       * @param {AssignmentSet} assignmentSet
       */
      assignActivityRankAttributes(assignmentSet) {
        assignmentSet.activities.forEach(
          (activity, index) => activity.assignment_set_rank = index + 1
        );
      },
      /**
       * @private
       * resets drag state to initial conditions
       */
      clearDragState() {
        this.dragState.hoverPosition = '';
        this.dragState.originalSetDueDate = null;
        this.dragState.setDueDate = null;
        this.dragState.entryIndex = null;
      },
      /**
       * @private
       * @param {Date} dateObj
       * @return {string} in format YYYY-MM-DD
      */
      dateToDatabaseDate(dateObj) {
        return format(dateObj, 'yyyy-MM-dd');
      },
      /**
       * @private
       * Sends a DELETE request destroy the specified set
       * @param {AssignmentSet} assignmentSet - set to be deleted
       */
      deleteSet(assignmentSet) {
        ajaxUtils.deleteFromEndpoint(
          `${this.endpointUrl}/${assignmentSet.id}`,
          (response) => {
            if (response.errors) {
              this.errors = response.errors;
            } else {
              this.revertToDefaultOrder(assignmentSet);
            }
          }
        );
      },
      /**
       * @private
       * Hide the custom order confirmation dialog, reset the
       * stashed unconfirmed change data, flag the set as having,
       * a custom order, and display the success message.
       * @param {AssignmentSet} assignmentSet
       */
      handleSuccessfulSave(assignmentSet) {
        this.showCustomOrderConfirmation = false;
        this.unconfirmedChange = null;
        assignmentSet.hasCustomOrder = true;
        this.setSuccessMessage(assignmentSet);
      },
      /**
       * @private
       * @param {DropData} dropData - parameters on where to insert
       * @param {Object} activityData - the activity to be inserted
       * @param {string} originalSetDueDate - The set the activity
       * was being dragged from.
       */
      insertDroppedActivity(dropData, activityData, originalSetDueDate) {
        const set = this.assignmentSets.find((set) => set.due_date === dropData.setDueDate);

        // Do nothing if attempting to drop into a different set than
        // the activity's original set.
        if (set.due_date !== originalSetDueDate) return;

        const currentIndex = set.activities.findIndex(
          (activity) => activity.activity_id === activityData.activity_id
        );
        const newIndex = this.newIndexFromDrop(dropData);

        if (newIndex === currentIndex) return;

        this.unconfirmedChange = { set, currentIndex, newIndex };

        if (this.isConfirmationNeeded(set)) {
          this.showCustomOrderConfirmation = true;
        } else {
          this.confirmCustomOrderChange();
        }
      },
      /**
       * @private
       * Returns false if "Don't ask me again" has been checked, or if the
       * specified assignmentSet has an id, indicating that the user
       * previously approved the confirmation dialog.
       * @param {AssignmentSet} assignmentSet
       * @return {boolean}
       */
      isConfirmationNeeded(assignmentSet) {
        if (this.skipConfirmations) return false;

        return !assignmentSet.id;
      },
      /**
       * @private
       * @param {DropData} dropData - parameters on where to insert
       * @return {number} index into which to splice
       */
      newIndexFromDrop(dropData) {
        if (dropData.entryIndex === '') {
          return 0;
        } else {
          return dropData.entryIndex;
        }
      },
      /**
       * @private
       * @param {Event} event - drop or dragover event
       * @return {Object} data about the current drag position
       */
      positionData(event) {
        const target = this.targetContainer(event.target);
        const targetData = target.dataset;
        const data = {
          entryIndex: targetData.entryIndex && Number(targetData.entryIndex),
          setDueDate: targetData.setDueDate,
          target: target,
        };
        const rect = target.getBoundingClientRect();
        if (event.pageY < (rect.top + rect.height / 2)) {
          data.position = 'above';
        } else {
          data.position = 'below';
        }
        return data;
      },
      /**
       * @private
       * @param {AssignmentSet} assignmentSet
       * Removes the set id to indicate that it is no longer persisted with
       * a custom order, and re-ranks the activities based on default (toc)
       * rank. Hides the dialog confirming the revert and clears the
       * stashed unconfirmed change data.
       */
      revertToDefaultOrder(assignmentSet) {
        assignmentSet.id = null;
        assignmentSet.hasCustomOrder = false;
        // make a copy of the default ordered assignment objects
        const defaultSet = this.assignmentSetsDefaultOrder.find(
          (elm) => elm.due_date === assignmentSet.due_date
        );
        const defaultActivitiesCopy = defaultSet.activities.map((act) => {
          const stringified = JSON.stringify(act);
          return JSON.parse(stringified);
        });
        assignmentSet.activities = defaultActivitiesCopy;

        this.showDefaultOrderConfirmation = false;
        this.unconfirmedChange = null;
      },
      /**
       * @private
       * Sends a POST request to create a new set, if a set with no id
       * is specified, or a PUT request to update an existing set, if the
       * specified set has an id.
       * @param {AssignmentSet} assignmentSet - set to be persisted
       */
      saveSet(assignmentSet) {
        if (assignmentSet.id) {
          ajaxUtils.putToEndpoint(
            `${this.endpointUrl}/${assignmentSet.id}`,
            { assignment_set: assignmentSet },
            (response) => {
              if (response.errors) {
                this.errors = response.errors;
              } else {
                this.handleSuccessfulSave(assignmentSet);
              }
            }
          );
        } else {
          ajaxUtils.postToEndpoint(
            this.endpointUrl,
            { assignment_set: assignmentSet },
            (response) => {
              if (response.errors) {
                this.errors = response.errors;
              } else {
                assignmentSet.id = response.assignment_set.id;
                this.handleSuccessfulSave(assignmentSet);
              }
            }
          );
        }
      },
      /**
       * @private
       * Sets a message on the set and schedules it to be cleared after
       * 2 seconds.
       * @param {AssignmentSet} assignmentSet
       */
      setSuccessMessage(assignmentSet) {
        assignmentSet.message = 'Changes saved';
        window.setTimeout(() => assignmentSet.message = null, 2000);
      },
      /**
       * @private
       * @param {HtmlElement} elm - drop target element
       * @return {HtmlElement} The elm itself or the nearest ancestor
       * that contains a setDueDate data attr.
       */
      targetContainer(elm) {
        if (elm.dataset.setDueDate) {
          return elm;
        } else {
          return this.targetContainer(elm.parentElement);
        }
      },
    },
  }
);

export default useAssignmentSetStore;
