let ExternalItem;

{
  let updatableProperties = ['categoryId', 'dueDate', 'lessonId', 'pointsPossible', 'title'];

  ExternalItem = class {
    /**
     * @constructor
     * @param {String} externalActivityId - the ID of the external activity.
     *                 It will be blank for a new external item.
     * @param {String} sectionId - the section ID for the external item
     * @param {String} startDate - the section ID for the external item
     * @param {String} endDate - the section ID for the external item
     */
    constructor(externalActivityId, sectionId, startDate, endDate, initialData = {}) {
      this.externalActivityId = externalActivityId;
      this.sectionId = sectionId;
      this.startDate = startDate;
      this.endDate = endDate;

      this.initialData = initialData;
      updatableProperties.forEach(prop => {
        this[prop] = this.initialData[prop];
      }, this);
    }

    /**
     * @summary Updates the state of the model.
     * @param {Object} externalItemData - hash containing values to update the model
     */
    update(externalItemData) {
      if (!this.validate(externalItemData)) {
        return false;
      }

      updatableProperties.forEach((prop) => {
        this[prop] = externalItemData[prop];
      }, this);

      return true;
    }

    /**
     * @summary Returns true if input is valid, false otherwise.
     * @param {Object} data - data to validate
     * @returns {Boolean}
     */
    validate(data) {
      if (data.title.trim() === '') { return false; }
      if (!Number.isSafeInteger(parseInt(data.pointsPossible, 10))) { return false; }
      if (data.lessonId === '') { return false; }
      if (data.categoryId === '') { return false; }
      if (data.dueDate < this.startDate || data.dueDate > this.endDate) { return false; }

      // Check that values are different from the initial settings
      // (if they aren't, there's no need to update the model)
      if (updatableProperties.every(prop => { return this.initialData[prop] == data[prop]; }, this)) { return false; }

      return true;
    }

    /**
     * @summary Returns the state of the model as an object.
     * The object returned by this method is sent to the server when the user creates
     * or updates an external item.
     * @returns {Object} Object representing the state of the model
     */
    data() {
      return {
        category_id: this.categoryId,
        due_date: this.dueDate,
        id: this.externalActivityId,
        lesson_id: this.lessonId,
        points_possible: this.pointsPossible,
        section_id: this.sectionId,
        title: this.title
      };
    }
  }
}

export default ExternalItem;
