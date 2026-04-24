import { getFromEndpoint } from 'shared/ajax_utils.js';

// Define the class name outside of the closure so that
// it can be exported.
let SectionMetricsObservable;

// Establish a closure to allow for private function definitions.
{
  // Define functionality that will be private to the class.
  let requestData = (obj, sectionId) => {
    let observers = obj.observers;
    let endpoint = `/institution_admin/section_metrics_data/${obj.programId}/${sectionId}`;

    getFromEndpoint(
      endpoint,
      (data) => {
        observers.forEach(observer => observer.update(data));
      }
    );
  };

  // Define the class.
  //
  // Because the class is defined within the closure, it can use the functionality
  // defined above.

  /**
   * @classdesc An instance of this class requests section-metrics data and, on
   * receiving it, updates a set of observers with the data.
   */
  SectionMetricsObservable = class {
    /**
     * @constructor
     * @param {String} programId - ID for the program
     * @param {Array} sectionIds - an array of section IDs
     */
    constructor(programId, sectionIds) {
      this.programId = programId;
      this.sectionIds = sectionIds;
    }

    /**
     * Registers an array of observers.
     * Note that each object in the array must implement an #update method.
     * @param {Array} observers - an array of observer objects
     */
    registerObservers(observers) {
      this.observers = observers;
    }

    /**
     * Iterates over an array of section IDs and requests section-metrics data
     * for each.
     */
    getMetricsData() {
      // TODO: I don't like assigning `this` to a value, but I don't want to make requestData
      //       public either.
      let thisObj = this;

      /**
       * For each section ID on page, request data.
       */
      this.sectionIds.forEach(sectionId => {
        // TODO: I can't get bind, apply, or call to work here
        requestData(thisObj, [sectionId]);
      });
    }
  }
}

export default SectionMetricsObservable;
