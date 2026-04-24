import LearningTrackHttp from 'features/learning_tracks/models/learning_track_http';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

describe('LearningTrackHttp', () => {
  const tracks = {
    tracks: {
      a: {
        description: 'Track A',
      },
    },
  };
  const sectionTrack = { description: 'Track 1' };
  const courseId = 2;
  const sectionId = 2;
  const programId = 79;
  const learningTrackUrl = `/instructor/${programId}/learning_tracks.json`;
  const sectionTrackUrl = `/instructor/79/section_learning_track/${sectionId}.json` +
  `?current_course_id=${courseId}`;
  let learningTrackHttp;

  describe('getTracks', () => {
    beforeEach(
      () => {
        spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
        fetchMock.mock(
          learningTrackUrl, { status: 200, body: tracks }
        );
        learningTrackHttp = new LearningTrackHttp(programId);
        learningTrackHttp.getTracks();
      }
    );

    afterEach(() => fetchMock.restore());

    it('makes a call to fetch learning tracks', () => {
      expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
        learningTrackUrl, jasmine.any(Function)
      );
    });
  });

  describe('getPreviousTrack', () => {
    beforeEach(
      () => {
        spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
        fetchMock.mock(
          sectionTrackUrl, { status: 200, body: sectionTrack }
        );
        learningTrackHttp = new LearningTrackHttp(programId);
        learningTrackHttp.getPreviousTrack(sectionId, courseId);
      }
    );

    afterEach(() => fetchMock.restore());

    it('makes a call to fetch section learning track', () => {
      expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
        sectionTrackUrl, jasmine.any(Function)
      );
    });
  });
});
