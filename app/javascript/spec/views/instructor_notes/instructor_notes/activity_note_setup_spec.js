import ActivityNote from 'views/instructor_notes/instructor_notes/activity_note_setup';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

VHL = {
  Music: { V1: {}},
  InstructorNotes: {},
};

VHL.InstructorNotes.Config = {
  cdnPrefix: 'cdnPrefix',
  endpoint: 'endpoint',
};

VHL.Music.V1.Disclosure = class Disclosure {
  toggle() {}
};

describe('ActivityNoteSetup', () => {
  const directionLineElmHtml =
    `<div id="direction_line"
          class="js-direction-line"
          data-instructor-notable="">
      <span>Listen to each question or statement.</span>
    </div>`;

  const notableEl1Html = `<div id="question_01" 
                               data-instructor-notable="">
                          </div>`;

  const notableElmsHtml = `<div id="question_02" 
                               data-instructor-notable="">
                          </div>`;

  const notableElsHtml = notableEl1Html + notableElmsHtml;

  document.body.innerHTML = `<div class="container">${directionLineElmHtml}${notableElsHtml}</div>`;

  const programId = 1;

  const activityId = 1;

  const activityNotes = [
    { id: 1, title: 'test', note_item_id: 'direction_line' },
    { id: 2, title: 'test', note_item_id: 'question_01' },
    { id: 3, title: 'test', note_item_id: 'question_02' },
  ];

  describe('getNotableElements', () => {
    it('should return notable elements', () => {
      const notableEls = ActivityNote.getNotableElements();
      const elIds = [...notableEls].map((el) => el.id);
      expect(elIds).toEqual(
        expect.arrayContaining(['direction_line', 'question_01', 'question_02'])
      );
    });
  });

  describe('getDirectionLineElm', () => {
    it('should return direction line element', () => {
      const dirEl = ActivityNote.getDirectionLineElm();
      expect(dirEl).toHaveClass('js-direction-line');
    });
  });

  describe('getNotes', () => {
    describe('When notes are present in dom rails-data', () => {
      const railsData = { activity_notes: activityNotes };

      it('should return notes from railsData', () => {
        const activityNote = new ActivityNote({ railsData });
        expect(activityNote.getNotes()).toEqual(
          expect.arrayContaining(railsData.activity_notes)
        );
      });
    });

    describe('When notes are not present in dom rails-data', () => {
      const activityNotesUrl = `/instructor/${programId}/activity/${activityId}/activity_notes`;

      beforeEach(() => {
        /* Mock the fetch call. */
        fetchMock.mock(activityNotesUrl, { status: 200, body: {}});
      });

      afterEach(() => {
        fetchMock.restore();
      });

      it('requests activity notes data', () => {
        spyOn(ajaxUtils, 'getFromEndpoint');
        const activityNote = new ActivityNote({
          railsData: {
            program_id: programId,
            activity_id: activityId,
          },
        });
        activityNote.getNotes();
        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          activityNotesUrl,
          jasmine.any(Function)
        );
      });
    });
  });

  describe('attachNotes', () => {
    describe('When allowsExpandedNotes is true', () => {
      it('should mount vue apps for each notable elements', async () => {
        const activityNote = new ActivityNote({
          allowsExpandedNotes: true,
          railsData: { activity_notes: activityNotes },
        });
        await activityNote.attachNotes();
        const apps = activityNote.activityNoteApps;

        expect(Object.keys(apps)).toEqual(
          expect.arrayContaining(['direction_line', 'question_01', 'question_02'])
        );
      });
    });

    describe('When allowsExpandedNotes is false', () => {
      it('should mount one app for the direction line', async () => {
        const activityNote = new ActivityNote({
          allowsExpandedNotes: false,
          railsData: { activity_notes: activityNotes },
        });
        await activityNote.attachNotes();
        const apps = activityNote.activityNoteApps;

        expect(Object.keys(apps)).toEqual(
          expect.arrayContaining(['direction_line'])
        );
      });
    });
  });
});
