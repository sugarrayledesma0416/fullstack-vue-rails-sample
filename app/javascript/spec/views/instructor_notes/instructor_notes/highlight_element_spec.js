import HighlightElements from 'views/instructor_notes/instructor_notes/highlight_elements';
import { getHtmlDocument, elmFromString } from '../../../support/utils';

const getDirectionLine = () => {
  return getHtmlDocument(`
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
  `);
};

const getMCQQ1 = () => {
  return elmFromString(`
    <div class="answer_positioning u-float-lt u-pad-lt-5"
      data-instructor-notable="" data-helpable-type="whole_question"
      id="question_01_whole_question" data-sidebar-reference="">
      <div class="answer_choices">
          <input type="hidden" name="question_01" value=""
          id="question_01_choice_00" data-field_type="radio">
          <div class="answer_blank u-mar-bot-10" id="question_01_choice_01_answer_blank"
            data-helpable-type="answer_blank">
            <input type="radio" name="question_01" value="1"
                id="question_01_choice_01" onchange="javascript: has_unsaved_work();">
            <label for="question_01_choice_01" style="display: inline">
                <span><text>Muy bien, gracias.</text></span>
            </label>
          </div>
          <div class="answer_blank u-mar-bot-10" id="question_01_choice_02_answer_blank"
          data-helpable-type="answer_blank">
            <input type="radio" name="question_01" value="2" id="question_01_choice_02"
            onchange="javascript: has_unsaved_work();">
            <label for="question_01_choice_02" style="display: inline">
                <span><text>Me llamo Graciela.</text></span>
            </label>
          </div>
      </div>
    </div>`);
};

const expandedNotesInput = (value) => {
  return elmFromString(`<input class="js-allows-expanded-notes ng-pristine ng-valid"
    type="hidden" data-allows-expanded-notes="${value}" ng-model="allows_expanded_notes"></input>`);
};

const validateHighlightProcess = (htmlDOM, notableElements) => {
  const directionLineElm = htmlDOM.querySelector('#direction_line');
  const directionLineClasses = directionLineElm.classList;

  notableElements.highlightNotable(directionLineElm);
  expect(directionLineClasses).toContain('highlighted_notable');

  notableElements.unhighlightNotable(directionLineElm);
  expect(directionLineClasses).not.toContain('highlighted_notable');
};

const createHtmlDom = (isAllowsExpandedNotes) => {
  const htmlDOM = getDirectionLine();
  htmlDOM.body.appendChild(getMCQQ1());
  htmlDOM.body.appendChild(expandedNotesInput(isAllowsExpandedNotes));
  return htmlDOM;
};

const initialiseData = (isAllowsExpandedNotes) => {
  const htmlDOM = createHtmlDom(isAllowsExpandedNotes);
  const allowsExpandedNotes = htmlDOM
    .querySelector('.js-allows-expanded-notes')
    .getAttribute('data-allows-expanded-notes');
  const notableElements = new HighlightElements(
    htmlDOM.querySelectorAll('[data-instructor-notable]'),
    allowsExpandedNotes
  );

  return { htmlDOM, notableElements };
};

describe('Highlight/Unhighlight Element on activity where allows-expanded-notes is true', () => {
  let data;
  beforeEach(() => {
    data = initialiseData(true);
  });

  it('call highlightNotable and unhighlightNotable fn on direction line and validate', () => {
    validateHighlightProcess(data.htmlDOM, data.notableElements);
  });

  it('call highlightNotable and unhighlightNotable fn on the activity content and validate', () => {
    const activityElm = data.htmlDOM.querySelector('#question_01_whole_question');
    data.notableElements.highlightNotable(activityElm);
    expect(
      activityElm.classList
    ).toContain('highlighted_notable');

    data.notableElements.unhighlightNotable(activityElm);
    expect(
      activityElm.classList
    ).not.toContain('highlighted_notable');
  });
});


describe('Highlight/Unhighlight Element on activity where allows-expanded-notes is false', () => {
  let data;
  beforeEach(() => {
    data = initialiseData(false);
  });

  it('call highlightNotable and unhighlightNotable fn on direction line and validate', () => {
    validateHighlightProcess(data.htmlDOM, data.notableElements);
  });

  it('activity content is not highlightable as allows-expanded-notes is false', () => {
    const activityElm = data.htmlDOM.querySelector('#question_01_whole_question');
    data.notableElements.highlightNotable(activityElm);
    expect(
      activityElm.classList
    ).not.toContain('highlighted_notable');
  });
});
