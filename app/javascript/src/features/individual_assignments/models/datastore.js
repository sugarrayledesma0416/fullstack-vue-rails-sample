import { reactive } from 'vue';
import { deepEqual } from 'fast-equals';

/**
 * Contains a matrix that represent the cells of a table with columns for
 * each assigned activity and rows for each student in a section. Provides
 * functions to help display the table, including changing displayed
 * columns based on UI interaction.
 */
export default class Datastore {
  /**
   * @param {Object} entries - The object keys are user ids for each
   * student in the section. The values are arrays of entries representing
   * cells in the table.
   * @param {string} onlyIndividual - Will either be 'true' or 'false' as
   * a string. Needs to be converted to a boolean.
   */
  constructor(entries, onlyIndividual) {
    this.originalEntries = JSON.stringify(entries);
    this.entries = reactive(entries);
    this.state = reactive(
      {
        activityIdBeingEdited: null,
        showOnlyIndividuallyAssignable: (onlyIndividual === 'true'),
      }
    );
  }

  /**
   * @return {Array} Entries for each assigned activity, filtered
   * based on whether all or just individually-assigned activities
   * are to be displayed.
   */
  get activityEntries() {
    return this.filterColumns(this.firstUserEntries);
  }

  /**
   * @return {boolean} Whether any property of any entry is different from
   * the copy stashed on initialization.
   */
  get hasChanges() {
    return !deepEqual(JSON.parse(this.originalEntries), this.entries);
  }

  /**
   * @return {boolean} Whether there are any entries.
   */
  get hasEntries() {
    return Object.keys(this.entries).length > 0;
  }

  /**
   * Groups activity columns by their strand, returning an object reflecting
   * each instance of a strand, which is used to generate column headers that
   * span the correct number of activity columns. Since assignments are sorted
   * by due date first, and then by strand, there might be multiple instances
   * of a strand with a given id displayed in the same grid (if that strand
   * has activities on different due dates). Therefore, it's not safe to just
   * group by strand id. Instead, the activities must be iterated over,
   * preserving their original sort order, and a new strand header produced
   * whenever the strand id changes.
   * @return {Array.<{color: string, count: number, id: number, name: string}>}
   */
  get strandHeaders() {
    return this.firstUserEntries.reduce(
      (memo, entry) => {
        if (this.state.showOnlyIndividuallyAssignable && !entry.individually_assignable) {
          return memo;
        }

        const last = memo.length > 0 && memo[memo.length - 1];
        if (last && last.id === entry.strand_id) {
          last.count++;
        } else {
          memo.push(this.newStrandObject(entry));
        }
        return memo;
      },
      []
    );
  }

  /**
   * Set the assignment with the assignable_id matching the specified
   * activityId as being individually-assigned to all students.
   * @param {number} activityId
   */
  checkAll(activityId) {
    this.forEachActivityEntry(
      activityId,
      (entry) => entry.individually_assigned = true
    );
  }

  /**
   * If the showOnlyIndividuallyAssignable flag is false, show all
   * columns, otherwise show only the ones that are individually
   * assignable.
   * @param {Array} columns - Can either be activity column headers or
   * per-student cells for each activity.
   * @return {Array} Columns that should be displayed.
   */
  filterColumns(columns) {
    return columns.filter(
      (column) => {
        return (
          !this.state.showOnlyIndividuallyAssignable ||
          column.individually_assignable
        );
      }
    );
  }

  /**
   * @param {number} activityId - activityId to mark as currently being edited
   */
  startEditing(activityId) {
    this.state.activityIdBeingEdited = activityId;
  }

  /**
   * Update the entries with the assignable_id matching the specified
   * activityId to have the specified individually-assignable status.
   * @param {number} activityId
   * @param {boolean} newValue - New individually_assignable value
   */
  updateAssignableState(activityId, newValue) {
    this.forEachActivityEntry(
      activityId,
      (entry) => entry.individually_assignable = newValue
    );
  }

  /**
   * Set the assignment with the assignable_id matching the specified
   * activityId to not be individually-assigned to any students.
   * @param {number} activityId
   */
  uncheckAll(activityId) {
    this.forEachActivityEntry(
      activityId,
      (entry) => {
        entry.individually_assigned = false;
        entry.individual_due_date = null;
      }
    );
  }

  /**
   * @param {number} activityId
   * @return {boolean} Whether assignments for activity have > 1 due date
   */
  hasVariedDueDates(activityId) {
    for (const entry of this.entriesForActivity(activityId)) {
      if (!entry.individual_due_date) {
        continue;
      }
      if (entry.individual_due_date !== entry.due_date) {
        return true;
      }
    }

    return false;
  }

  /**
   * @private
   * @return {Array} The entries for the first user, used to generate
   * column headers. Could be fetched from any arbitrary user as the
   * activity-specific data should be the same for every user.
   */
  get firstUserEntries() {
    return this.entries[Object.keys(this.entries)[0]];
  }

  /**
   * @private
   * Returns a generator that yields the entries for the given activityId.
   *
   * The entries object has user ids as keys and arrays of entries for
   * each user as values. The method creates and returns a generator that
   *   - iterates through the array of arrays
   *   - for each array of entries, finds and yields the entry with an
   *     assignable_id that matches the specified activityId
   *
   * @param {number} activityId
   * @return {Generator}
   */
  entriesForActivity(activityId) {
    const entries = Object.values(this.entries);

    /**
     * Every invocation of entriesForActivity returns a new generator instance.
     * This is to allow us to iterate through the entries as many times as
     * needed. The generator is not "rewindable" and so may be consumed only
     * once.
     */
    return function* () {
      for (let userIndex = 0; userIndex < entries.length; userIndex++) {
        yield entries[userIndex].find((entry) => entry.assignable_id === activityId);
      }
    }();
  }

  /**
   * @private
   * @param {number} activityId
   * @param {function} callback - Function to be executed for each
   * matching entry, with that entry passed as its argument.
   */
  forEachActivityEntry(activityId, callback) {
    for (const entry of this.entriesForActivity(activityId)) {
      callback(entry);
    }
  }

  /**
   * @private
   * Creates a new strand object with an activity count of 1 from a given
   * entry.
   * @param {Object} entry
   * @param {string} entry.strand_color - hex code
   * @param {number} entry.strand_id
   * @param {string} entry.strand_name
   * @return {{color: string, count: number, id: number, name: string}}
   */
  newStrandObject(entry) {
    return {
      color: entry.strand_color,
      count: 1,
      id: entry.strand_id,
      name: entry.strand_name,
    };
  }
}
