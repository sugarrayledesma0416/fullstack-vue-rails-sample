/** This composable provides methods related to help request modal
 * @return {Object} - Object wrapping following methods
 * getDefaultModalData,
 * getModalData,
 * getSubmitFailureMessage,
 * getSubmitSuccessMessage,
 */
const useHelpRequestModalHelper = () => {
  const {
    getDialogTitle,
    getDirections,
    getInstructorTextWhenNoSubmit,
  } = useHelpRequestModalHtmlHelper();

  const {
    getSubmitFailureMessage,
    getSubmitSuccessMessage,
  } = useHelpRequestModalMessageHelper();

  /**
   * This method returns configuration data for Add Help Request dialog
   * @param {String} userType
   * @param {String} requestType
   * @return {Object} - Configuration data for Add Help Request dialog
   */
  const getModalData = (userType, requestType) => {
    if (userType === 'instructor') {
      return getInstructorModalData(requestType);
    } else {
      return getStudentModalData(requestType);
    }
  };

  /**
   * This method returns configuration data for Add Help Request dialog for instructor
   * @param {String} requestType
   * @return {Object} - Configuration data for Add Help Request dialog
   */
  const getInstructorModalData = (requestType) => {
    if (requestType === 'request_help' || requestType === 'request_review') {
      return getInstructorModalDataWhenNoSubmit(requestType);
    }
    const requestDialog = {};
    requestDialog.directionsVisible = true;
    requestDialog.requestTextareaVisible = true;
    requestDialog.instructorTextareaVisible = false;
    setSeverityLevelInData(requestDialog, requestType);
    requestDialog.title = getDialogTitle(requestType);
    requestDialog.directionsText = getDirections(requestType);
    return requestDialog;
  };

  /**
   * This method returns configuration data for Add Help Request dialog for student
   * @param {String} requestType
   * @return {Object} - Configuration data for Add Help Request dialog
   */
  const getStudentModalData = (requestType) => {
    const requestDialog = {};
    requestDialog.requestTextareaVisible = true;
    requestDialog.directionsVisible = true;
    requestDialog.instructorTextareaVisible = false;
    setSeverityLevelInData(requestDialog, requestType);
    requestDialog.title = getDialogTitle(requestType);
    requestDialog.directionsText = getDirections(requestType);
    return requestDialog;
  };

  /**
   * This method returns configuration data for Add Help Request dialog for instructor
   * when request can not be submitted for instructor
   * @param {String} requestType
   * @return {Object} - Configuration data for Add Help Request dialog
   */
  const getInstructorModalDataWhenNoSubmit = (requestType) => {
    const requestDialog = {};
    // Display error message saying that an Instructor cannot submit help / review requests.
    requestDialog.instructorText = getInstructorTextWhenNoSubmit();
    // Disable the button to submit the Request.
    requestDialog.submitButtonEnabled = false;
    requestDialog.requestSeverityLevelVisible = false;
    // Hide the Text Area and display the Instructor Message
    requestDialog.requestTextareaVisible = false;
    requestDialog.directionsVisible = false;
    requestDialog.instructorTextareaVisible = true;
    requestDialog.title = getDialogTitle(requestType);
    return requestDialog;
  };

  /**
   * This method sets configuration data in the given param object, related to
   * Severity Level dropdown in Add Help Request dialog,
   * @param {Object} requestDialog - Data model to be updated with severity level related keys
   * @param {String} requestType
   */
  const setSeverityLevelInData = (requestDialog, requestType) => {
    if (requestType === 'report_technical_problem') {
      requestDialog.requestSeverityLevelVisible = true;
      requestDialog.severityLevelValue = 2;
    } else {
      requestDialog.requestSeverityLevelVisible = false;
    }
  };

  /**
   * This method returns default configuration data for Add Help Request dialog
   * @return {Object} - Default configuration data for Add Help Request dialog
   */
  const getDefaultModalData = () => {
    const requestDialog = {
      commentValue: '',
      directionsText: '',
      directionsVisible: true,
      instructorText: '',
      instructorTextareaVisible: false,
      requestSeverityLevelVisible: false,
      requestTextareaVisible: true,
      severityLevelValue: 2,
      submitButtonEnabled: false,
      title: '',
    };
    return requestDialog;
  };

  return {
    getDefaultModalData,
    getModalData,
    getSubmitFailureMessage,
    getSubmitSuccessMessage,
  };
};

/** This composable provides methods related to help request modal html
 * @return {Object} - Object wrapping following methods
 * getDialogTitle,
 * getDirections,
 * getInstructorTextWhenNoSubmit,
 */
const useHelpRequestModalHtmlHelper = () => {
  /**
   * This method returns title text for Add Help Request dialog based on request type
   * @param {String} requestType
   * @return {String} - Add Help Request dialog title
   */
  const getDialogTitle = (requestType) => {
    const titleMap = {
      report_content_problem: 'Report Content Error',
      report_technical_problem: 'Report Technical Problem',
      request_help: 'Request Instructor Help',
      request_review: 'Review My Score',
    };
    return titleMap[requestType];
  };

  /**
   * This method returns direction text in HTML for Add Help Request dialog based on request type
   * @param {String} requestType
   * @return {String} - HTML which displays direction to the user about how to add the request
   */
  const getDirections = (requestType) => {
    let directionsText;
    switch (requestType) {
    case 'request_help':
      directionsText = getDirectionsForRequestHelp();
      break;
    case 'request_review':
      directionsText = getDirectionsForRequestReview();
      break;
    case 'report_technical_problem':
      directionsText = getDirectionsForTechnicalProblem();
      break;
    case 'report_content_problem':
      directionsText = getDirectionsForContentProblem();
      break;
    default:
      directionsText = '';
      break;
    }
    return directionsText;
  };

  /**
   * This method returns direction text in HTML for Add Help Request dialog for 'request_help'
   * @return {String} - HTML which displays direction to the user about how to add the request
   */
  const getDirectionsForRequestHelp = () => {
    return `
      <div>
        Add your comment below to attach it to the selected area.
        Your instructor will receive a notification that you require help.
      </div>`;
  };

  /**
   * This method returns direction text in HTML for Add Help Request dialog for 'request_review'
   * @return {String} - HTML which displays direction to the user about how to add the request
   */
  const getDirectionsForRequestReview = () => {
    return `
      <div>
        Add your comment below to attach it to the selected content area
        and submit it to your Instructor.
      </div>
      <br>
      <div>
        Correct answers and unanswered questions cannot be submitted for review.
      </div>`;
  };

  /**
   * This method returns direction text in HTML for Add Help Request dialog
   * for 'report_technical_problem'
   * @return {String} - HTML which displays direction to the user about how to add the request
   */
  const getDirectionsForTechnicalProblem = () => {
    return `
      <div>
        Include a comment and submit it for Technical Support to receive it.
      </div>`;
  };

  /**
   * This method returns direction text in HTML for Add Help Request dialog
   * for 'report_content_problem'
   * @return {String} - HTML which displays direction to the user about how to add the request
   */
  const getDirectionsForContentProblem = () => {
    return `
      <div>
        Add your comment below to attach it to the selected content area
        and submit it to Vista Higher Learning.
      </div>`;
  };

  /**
   * This method returns direction text for instructor for Add Help Request dialog
   * when request can not be submitted for instructor
   * @return {String}
   */
  const getInstructorTextWhenNoSubmit = () => {
    return `As an instructor you cannot submit a help
      or review request. This is where the student would enter a comment before
      sending the request to you for consideration.`;
  };

  return {
    getDialogTitle,
    getDirections,
    getInstructorTextWhenNoSubmit,
  };
};

/** This composable provides methods related to help request modal success/failure message
 * @return {Object} - Object wrapping following methods
 * getSubmitFailureMessage,
 * getSubmitSuccessMessage,
 */
const useHelpRequestModalMessageHelper = () => {
  /**
   * This method returns failure message for help request submission based on request type
   * @param {String} requestType
   * @return {String} - Failure message
   */
  const getSubmitFailureMessage = (requestType) => {
    const msgMap = {
      report_content_problem: 'Failed to submit the content problem!',
      report_technical_problem: 'Failed to submit the technical problem!',
      request_help: 'Failed to submit the help request!',
      request_review: 'Failed to submit the review request!',
    };
    return msgMap[requestType] ?? msgMap.request_help;
  };

  /**
   * This method returns success message for help request submission based on request type
   * @param {String} requestType
   * @return {String} - Success message
   */
  const getSubmitSuccessMessage = (requestType) => {
    const msgMap = {
      report_content_problem: 'Content problem successfully submitted!',
      report_technical_problem: 'Technical problem successfully submitted!',
      request_help: 'Help request successfully submitted!',
      request_review: 'Review request successfully submitted!',
    };
    return msgMap[requestType] ?? msgMap.request_help;
  };

  return {
    getSubmitFailureMessage,
    getSubmitSuccessMessage,
  };
};

export default useHelpRequestModalHelper;
