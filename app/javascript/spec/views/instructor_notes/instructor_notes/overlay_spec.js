import Overlay from 'views/instructor_notes/instructor_notes/overlay';
import { getHtmlDocument, elmFromString } from '../../../support/utils';

const cancelInstructorNote = () => {
  return getHtmlDocument(`
    <div class="c-flash-banner-group c-instructor-note-flash js-instructor-note-flash
    test-instructor-note-flash-banner">
      <div class="c-flash-banner  c-flash-banner--warning" role="alert">
        <div class="l-media">
          <div class="l-media__img">
              <span class="c-flash-banner__icon  c-flash-banner__icon--warning"></span>
              <span class="u-screen-reader-only">warning</span>
          </div>
          <div class="l-media__body  test-instructor-note-body ">
              <div class="js-instructor-note-flash-msg">
                Choose the selectable area to add your Instructor Note. <br>
                This note will appear to all students in all of your courses.
              </div>
              <div class="u-mar-top-12">
                <button type="button" class="
                    c-no-button is-navigable js-instructor-note-cancel">
                Cancel Instructor Note
                </button>
              </div>
          </div>
        </div>
      </div>
    </div>
    `);
};

const getDirectionLine = () => {
  return elmFromString(
    `
    <div id="direction_line" class="description-area  c-activity-context__directions
    js-direction-line" data-instructor-notable="" data-helpable-type="direction_line">
      <h3 class="u-no-visual" lang="en">
          Instructions
      </h3>
      <span lang="en">
          <dl lang="en">
            Listen to each question or statement and choose the correct response.
          </dl>
      </span>
    </div>
    `);
};


describe('Overlay', () => {
  let htmlDOM; let notesBanner; let cancelFlashBtn;
  beforeEach(() => {
    htmlDOM = cancelInstructorNote();
    htmlDOM.body.appendChild(getDirectionLine());
    notesBanner = htmlDOM.querySelector('.js-instructor-note-flash');
    cancelFlashBtn = htmlDOM.querySelector('.js-instructor-note-cancel');
  });

  it('show overlay', () => {
    Overlay.show(notesBanner, cancelFlashBtn);
    expect(
      htmlDOM.querySelector('.js-instructor-note-flash').classList
    ).not.toContain('u-hidden');

    const overlay = document.querySelector('.js-transparent-overlay-instructor-note');
    const hotspotElmsLength = overlay.querySelectorAll('.js-proxy-hotspot').length;
    expect(
      overlay.querySelectorAll('.js-proxy-hotspot')[0]
    ).toHaveClass('js-modal-a11y__first-focus-element');

    expect(
      overlay.querySelectorAll('.js-proxy-hotspot')[0]
    ).toHaveClass('js-modal-a11y__default-focus');

    expect(
      overlay.querySelectorAll('.js-proxy-hotspot')[hotspotElmsLength - 1]
    ).toHaveClass('js-modal-a11y__last-focus-element');

    expect(
      overlay
    ).toHaveClass('c-help-request-info-mode');

    expect(
      overlay
    ).not.toHaveClass('u-hidden');
  });

  it('close overlay', () => {
    Overlay.show(notesBanner, cancelFlashBtn);
    Overlay.close(notesBanner);
    expect(
      htmlDOM.querySelector('.js-instructor-note-flash').classList
    ).toContain('u-hidden');

    const overlay = document.querySelector('.js-transparent-overlay-instructor-note');
    expect(
      overlay
    ).not.toHaveClass('c-help-request-info-mode');

    expect(
      overlay
    ).toHaveClass('u-hidden');
  });
});
