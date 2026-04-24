import AddHelpRequest from 'features/get_help/AddHelpRequest';
import { createApp } from 'vue';

/** Class representing HelpRequest Setup. */
class HelpRequestSetup {
  /**
   * Set up the configuration required for mounting Help Request vue apps.
   * @param {object} options
   * options parameter includes following:
   * 1. railsData (object): rails data includes following
   * activity_id: Number
   * activity_state: String
   * cms_activity_id: Number
   * cms_revision_id: Number
   * http_referer: String
   * program_id: Number
   * request_params: { controller: String, action: String, section_id: String, id: String }
   * question_id: String
   * section_id: Number
   * user_id: Array<Number>
   * user_type: String
   * 2. requestSeverityLevels (Array): severity level options for problem reporting.
   * 3. userType (string): User type of current user (Instructor or
   *    Student).
   */
  constructor({ railsData, requestSeverityLevels, userType }) {
    this.railsData = railsData;
    this.requestSeverityLevels = requestSeverityLevels;
    this.userType = userType;
  }

  /**
   * initAddHelpRequest.
   * Mounts Add Help Request app on the '.js-add-help-request-app'.
   * @return {object} vm Add Help Request vue object.
   */
  initAddHelpRequest() {
    const hostElm = document.querySelector('.js-add-help-request-app');
    const app = createApp(AddHelpRequest, {
      activityId: this.railsData.activity_id,
      payloadFromRails: this.railsData,
      requestSeverityLevels: this.requestSeverityLevels,
      sectionId: this.railsData.section_id,
      userType: this.userType,
    });
    const vm = app.mount(hostElm);
    return vm;
  }
}

export default HelpRequestSetup;
