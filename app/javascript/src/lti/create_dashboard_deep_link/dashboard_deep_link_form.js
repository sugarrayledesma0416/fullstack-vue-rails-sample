import { postToEndpoint } from '../../shared/ajax_utils.js';

class DashboardDeepLinkForm {
  constructor(formElm) {
    this.formElm = formElm;
    this.bindSubmit();
  }

  postJwtData() {
    postToEndpoint(
      `${location.origin}/lti/deep_link_jwt`,
      {
        launch_guid: this.launchGuid(),
        program_id: this.programId(),
        view: 'dashboard'
      },
      (data) => {
        this.updateJwtField(data.jwt);
        this.formElm.submit();
      }
    );
  }

  updateJwtField(jwt) {
    let jwtField = this.formElm.querySelector('.js-deep-link-jwt-field');
    jwtField.value = jwt;
  }

  launchGuid() {
    return this.formElm.querySelector('.js-deep-link-launch-guid').value;
  }

  programId() {
    return this.formElm.querySelector('.js-deep-link-program-id').value;
  }

  bindSubmit() {
    let submitButton = this.formElm.querySelector('.js-deep-link-submit-button');
    submitButton.addEventListener(
      'click',
      () => { this.postJwtData(); }
    );
  }
}

export default DashboardDeepLinkForm;
