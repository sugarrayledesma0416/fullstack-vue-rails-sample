import ExistingRequestSetup from 'views/get_help/existing_request_setup';
import { getHtmlDocument } from '../../support/utils';

const getDirectionLine = () => {
  return getHtmlDocument(`<div class="c-activity-context__content">
      <div id="direction_line"
          class="description-area c-activity-context__directions js-direction-line"
          data-instructor-notable=""
          data-helpable-type="direction_line">
          <h3 class="u-no-visual" lang="en">
              Instructions
          </h3>
          <span lang="en">
              <dl lang="en">
                  Listen to each question or statement and choose the correct response.
              </dl>
          </span>
      </div>
  </div>`);
};
const getMetaData = () => {
  return {
    sectionId: '53',
    activityId: '46220',
    userType: 'Student',
    programId: '80',
  };
};

describe('when existing requests is added', () => {
  describe('get helpable element where existing request will be attached', () => {
    let helpableElement;
    beforeAll(() => {
      document.body = getDirectionLine().body;
      const existingRequestSetup = new ExistingRequestSetup({
        metaData: getMetaData(),
      });
      helpableElement = existingRequestSetup.getHelpableElement('direction_line', '24');
    });
    it('gets helpable element with id direction_line', () => {
      expect(helpableElement.id).toBe('direction_line');
    });
    it('gets helpable element with helpable type attribute as direction_line', () => {
      expect(helpableElement.getAttribute('data-helpable-type')).toBe('direction_line');
    });
  });

  describe('create element to add existing request', () => {
    let requestElement;
    beforeAll(() => {
      document.body = getDirectionLine().body;
      const existingRequestSetup = new ExistingRequestSetup({
        metaData: getMetaData(),
      });
      requestElement = existingRequestSetup.createRequestElement('direction_line', '24');
    });
    it('returns an element to add requests without a class', () => {
      expect(requestElement.classList.length).toBe(0);
    });
    it('returns an element next to direction line element', () => {
      expect(
        document.querySelector('#direction_line'
        ).nextElementSibling).toBe(requestElement);
    });
  });
});
