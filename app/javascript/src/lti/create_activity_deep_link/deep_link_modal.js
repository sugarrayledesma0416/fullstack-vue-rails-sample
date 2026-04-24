import { postToEndpoint } from '../../shared/ajax_utils.js';

class DeepLinkModal {
  constructor(rootElm, links) {
    this.rootElm = rootElm;
    this.jwtField = rootElm.querySelector('.js-deep-link-jwt-field');
    this.linkInfoDiv = rootElm.querySelector('.js-deep-link-info');
    this.launchGuid = rootElm.querySelector('.js-deep-link-launch-guid').value;
    this.bindLinks(links);
  }

  postJwtData(activityId) {
    postToEndpoint(
      `${location.origin}/lti/deep_link_jwt`,
      {
        activity_id: activityId,
        launch_guid: this.launchGuid
      },
      (data) => {
        this.jwtField.value = data.jwt;
        this.linkInfoDiv.innerText = data.link_info;

        $(this.rootElm).vhlModal('open');
      }
    );
  }

  handleActivityClick(event) {
    let activityId = event.target.getAttribute('data-js-activity-id');
    this.postJwtData(activityId);
  }

  bindLinks(links) {
    links.forEach(
      (link) => {
        link.addEventListener(
          'click',
          (event) => { this.handleActivityClick(event); }
        );
      }
    )
  }
}

export default DeepLinkModal;
