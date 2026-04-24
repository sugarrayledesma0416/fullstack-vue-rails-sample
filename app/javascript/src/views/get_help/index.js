import StudentRequest from './student_request';
import * as ajaxUtils from 'shared/ajax_utils';
import HelpRequestSetup from './help_request_setup';
import ExistingRequestSetup from './existing_request_setup';
import { metaTagContent } from 'shared/utils';
import FlashBannerSetup from 'features/flash_banner/flash_banner_setup';

const rulesRequest = () => {
  return new Promise((resolve) => {
    ajaxUtils.getFromEndpoint(
      '/help_request_rules.json',
      (data) => {
        resolve(data);
      }
    );
  });
};

const initHelpRequestApps = () => {
  const railsData = JSON.parse(
    document
      .querySelector('.js-help-request-rails-data')
      .getAttribute('data-from-dom')
  );
  const requestSeverityLevels = JSON.parse(
    document
      .querySelector('.js-help-request-severity-levels')
      .getAttribute('data-from-dom')
  );
  const helpRequestSetup = new HelpRequestSetup({
    railsData,
    userType: railsData.user_type,
    requestSeverityLevels,
  });
  helpRequestSetup.initAddHelpRequest();
};

const getMetaData = () => {
  return {
    sectionId: metaTagContent('VHL.section_id'),
    activityId: metaTagContent('VHL.activity_id'),
    userType: metaTagContent('VHL.user_type'),
    programId: metaTagContent('VHL.program_id'),
  };
};

document.addEventListener('DOMContentLoaded', async () => {
  const requestRules = await rulesRequest();
  const studentRequest = new StudentRequest(requestRules);
  studentRequest.clickRequestTypes();
  studentRequest.bindRequestEnded();

  const addRequestHostElm = document.querySelector('.js-add-help-request-app');
  if (addRequestHostElm) {
    initHelpRequestApps();
  }
  const existingRequestSetup = new ExistingRequestSetup({
    metaData: getMetaData(),
  });
  existingRequestSetup.addRequests();

  FlashBannerSetup.init();
});
