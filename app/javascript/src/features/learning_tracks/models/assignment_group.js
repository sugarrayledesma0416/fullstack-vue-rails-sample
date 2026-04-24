/** Class representing an Assignment Group. */
class AssignmentGroup {
  /**
   * Set up the configutation required for initializing
   * AssignmentGroup.
   * @param {string} name - name of the assignment group.
   * @param {string} strand - strand name.
   * @param {string} lesson - lesson name.
   */
  constructor(name, strand, lesson) {
    this.name = name;
    this.strand = strand;
    this.lesson = lesson;
    this.activities = [];
    this.totalMinutes = 0;
  }

  /**
   * Build a new assignment group from an assignment.
   * @param {Object} assignment - assignment object.
   * @return {Object} assignment group object.
   */
  static build(assignment) {
    const strand = assignment.activity.strand_name;
    const lesson = assignment.activity.lesson_name;
    const group = new AssignmentGroup(assignment.group, strand, lesson);

    group.addActivity(assignment.activity);

    return group;
  }

  /**
   * Add a new activity to the assignment group activities.
   * @param {Object} activity - activity object.
   */
  addActivity(activity) {
    this.activities.push(activity);
    this.totalMinutes += activity.minutes_to_complete;
  }

  /**
   * Add a new activity to the begining of assignment
   * group activities.
   * @param {Object} activity - activity object.
   */
  addActivityToFront(activity) {
    this.activities.unshift(activity);
    this.totalMinutes += activity.minutes_to_complete;
  }

  /**
   * Delete an activity from the assignment group activities.
   * @param {number} index - index of activity.
   * @return {Object} - activity object.
   */
  deleteActivity(index) {
    const activity = this.activities.splice(index, 1)[0];
    this.totalMinutes -= activity.minutes_to_complete;
    return activity;
  }
}

export default AssignmentGroup;
