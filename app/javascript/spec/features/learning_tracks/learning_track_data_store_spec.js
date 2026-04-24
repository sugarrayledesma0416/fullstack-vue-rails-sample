import { reactive } from 'vue';
import * as ajaxUtils from 'shared/ajax_utils';
import AssignmentCalendar from 'features/learning_tracks/models/assignment_calendar';
import fetchMock from 'fetch-mock';
import LearningTrackDataStore from 'features/learning_tracks/learning_track_data_store';
import useLearningTrack from 'features/learning_tracks/use_learning_track';

// Class to mock moment js implementation for the test cases
class MomentCls {
  isAfter() {}
}

/**
 * Get instance of MomentCls
 * @return {MomentCls} - Instance of MomentCls
 */
function momentFn() {
  return new MomentCls();
}

// Mock moment on window object and allow for initialization of moment() without 'new'
window.moment = momentFn;

const parentModel = {
  store: reactive({
    sectionSource: { type: 'section' },
    learningTracksConfig: {
      chooseTrack: true,
      previousCourses: [{
        id: 39,
        name: 'sddf',
        sections: [{ id: 54, name: 'test 1234' }],
      }],
    },
    setupDescriptions: {},
    disableAllControls: false,
    unitRange: {},
  }),
};

const config = { instAdmin: false, programId: 79 };

const getLearningTracksJson = {
  strands: { Contextos: { color: '#BE0027', name: 'Contextos' }},
  tracks: {
    Communicative: { description: '<b>Supports</b>', subtracks: { Complete: {}}},
  },
};

let learningTrackData;

describe('LearningTrackDataStore', () => {
  describe('#initialize', () => {
    beforeEach(() => {
      learningTrackData = new LearningTrackDataStore(parentModel);
    });

    it('contains default value of chooseTrack as "true"', () => {
      expect(learningTrackData.chooseTrack).toBeTruthy();
    });

    it('contains default value of VOL as "true"', () => {
      expect(learningTrackData.store.VOL).toBeTruthy();
    });

    it('contains 25 properties to learning Track data store.', () => {
      expect(Object.keys(learningTrackData.store).length).toEqual(25);
    });
  });

  describe('#isTemplateChooserDisabled', () => {
    beforeEach(() => {
      learningTrackData = new LearningTrackDataStore(parentModel);
    });

    it('contains default value as "false"', () => {
      expect(learningTrackData.isTemplateChooserDisabled).toBeFalsy();
    });

    it('returns "true" if disableAllControls is set to true', () => {
      learningTrackData.parentDataStore.disableAllControls = true;
      expect(learningTrackData.isTemplateChooserDisabled).toBeTruthy();
    });
  });

  describe('#sectionSourceType', () => {
    beforeEach(() => {
      learningTrackData = new LearningTrackDataStore(parentModel);
    });

    it('contains default value as "false"', () => {
      expect(learningTrackData.sectionSourceType).toEqual('section');
    });

    it('set sectionSourceType to "course"', () => {
      learningTrackData.sectionSourceType = 'course';
      expect(learningTrackData.sectionSourceType).toEqual('course');
    });
  });

  describe('#setupTracks', () => {
    beforeEach(() => {
      learningTrackData = new LearningTrackDataStore(parentModel);
    });

    it('contains default value as "false"', () => {
      expect(learningTrackData.setupTracks).toEqual(
        parentModel.store.setupDescriptions.learning_tracks
      );
    });
  });

  // TODO: this will be fixed in next PR.
  // describe('#clickTemplateChooser', () => {
  //   beforeEach(() => {
  //     learningTrackData = new LearningTrackDataStore(parentModel);
  //     learningTrackData.clickTemplateChooser();
  //   });

  //   it('contains value of chooseTrack as "true"', () => {
  //     expect(learningTrackData.chooseTrack).toBeTruthy();
  //   });
  // });

  describe('#preDefinedSubtrackLength', () => {
    let spy;
    beforeEach(async () => {
      spy = spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      fetchMock.mock(
        `/instructor/${config.programId}/learning_tracks.json`,
        { status: 200, body: getLearningTracksJson }
      );

      learningTrackData = new LearningTrackDataStore(parentModel);
      const assignmentCalendar = new AssignmentCalendar();
      const { updateDataStore } = useLearningTrack(
        assignmentCalendar, config, learningTrackData
      );
      await updateDataStore();
    });

    it('contains "Communicative" subtracks length as "1"', () => {
      expect(spy).toHaveBeenCalledWith(
        `/instructor/${config.programId}/learning_tracks.json`, jasmine.any(Function)
      );
      expect(learningTrackData.preDefinedSubtrackLength('Communicative')).toEqual(1);
    });
  });

  describe('#datesAreLocked', () => {
    beforeEach(() => {
      learningTrackData = new LearningTrackDataStore(parentModel);
    });

    it('returns datesAreLocked as false', () => {
      expect(learningTrackData.datesAreLocked).toBeFalsy();
    });
  });

  describe('#usePredefinedTrack', () => {
    beforeEach(() => {
      learningTrackData = new LearningTrackDataStore(parentModel);
      learningTrackData.usePredefinedTrack(
        'Communicative',
        'Complete',
        {}
      );
    });

    it('sets chooseTrack as false', () => {
      expect(learningTrackData.chooseTrack).toBeFalsy();
    });

    it('sets selectedTrackName as "Communicative: Complete"', () => {
      expect(learningTrackData.parentDataStore.selectedTrackName).toEqual(
        'Communicative: Complete'
      );
    });

    it('sets insufficientLicenseGroups as false', () => {
      expect(learningTrackData.store.insufficientLicenseGroups).toBeFalsy();
    });

    it('sets parent respectDueDates as false', () => {
      expect(learningTrackData.parentDataStore.respectDueDates).toBeFalsy();
    });

    it('sets parent usingPredefinedTrack as false', () => {
      expect(learningTrackData.parentDataStore.usingPredefinedTrack).toBeTruthy();
    });
  });

  describe('#currentStep', () => {
    beforeEach(() => {
      learningTrackData = new LearningTrackDataStore(parentModel);
    });

    it('returns 0 when chooseTrack is true', () => {
      learningTrackData.chooseTrack = true;
      expect(learningTrackData.currentStep).toEqual(0);
    });

    it('returns 1 when there are units but none is selected', () => {
      learningTrackData.chooseTrack = false;

      learningTrackData.parentDataStore.unitRange = {
        firstUnitIndex: '',
        lastUnitIndex: '-1',
      };

      learningTrackData.store.units = [{
        'id': 304,
        'name': 'Lección 2 | En la universidad',
        'rank': 1,
        'program_id': 79,
        'label': 'Lección 2',
        'created_at': '2014-07-22T16:40:46-04:00',
        'updated_at': '2014-07-22T16:40:46-04:00',
        'toc_location': 90032,
        'media_item_id': 145529,
        'use_type': 'Unit',
        'released': true,
        'index': '1',
      }];

      expect(learningTrackData.currentStep).toEqual(1);
    });

    it('returns 2 when unitsSelected but no day is selected', () => {
      learningTrackData.chooseTrack = false;

      learningTrackData.parentDataStore.unitRange = {
        firstUnitIndex: '0',
        lastUnitIndex: '1',
      };

      learningTrackData.store.units = [{
        'id': 304,
        'name': 'Lección 2 | En la universidad',
        'rank': 1,
        'program_id': 79,
        'label': 'Lección 2',
        'created_at': '2014-07-22T16:40:46-04:00',
        'updated_at': '2014-07-22T16:40:46-04:00',
        'toc_location': 90032,
        'media_item_id': 145529,
        'use_type': 'Unit',
        'released': true,
        'index': '1',
      }];

      expect(learningTrackData.currentStep).toEqual(2);
    });

    it('returns 3 when unitsSelected and day is selected', () => {
      learningTrackData.store.selectedDayValues = [1];
      expect(learningTrackData.currentStep).toEqual(3);
    });

    describe('when neither unit nor day are selected and chooseTrack is false',
      () => {
        it('returns 2 when copy Instructor-created Activities and Items has been checked',
          () => {
            parentModel.assignmentCalendar = { copyIgc: true };
            learningTrackData = new LearningTrackDataStore(parentModel);
            expect(learningTrackData.currentStep).toEqual(2);
          }
        );

        it('returns -1 when copy Instructor-created Activities and Items is not checked',
          () => {
            parentModel.assignmentCalendar = { copyIgc: false };
            learningTrackData = new LearningTrackDataStore(parentModel);
            expect(learningTrackData.currentStep).toEqual(-1);
          }
        );
      }
    );
  });

  describe('#showSelectCourseMsg', () => {
    beforeEach(() => {
      learningTrackData = new LearningTrackDataStore(parentModel);
    });

    it('returns true when no copy options are checked, no assignments, and external items exist', () => {
      const assignmentCalendar = { copyIgc: false, copyIac: false };
      const sectionHasAssignments = false;
      const externalItems = ['item1', 'item2'];

      const result = learningTrackData.showSelectCourseMsg(assignmentCalendar, sectionHasAssignments, externalItems);
      expect(result).toBeTruthy();
    });

    it('returns false when there are assignments', () => {
      const assignmentCalendar = { copyIgc: false, copyIac: false };
      const sectionHasAssignments = true;
      const externalItems = ['item1', 'item2'];

      const result = learningTrackData.showSelectCourseMsg(assignmentCalendar, sectionHasAssignments, externalItems);
      expect(result).toBeFalsy();
    });

    it('returns false when copy IGC is checked', () => {
      const assignmentCalendar = { copyIgc: true, copyIac: false };
      const sectionHasAssignments = false;
      const externalItems = ['item1', 'item2'];

      const result = learningTrackData.showSelectCourseMsg(assignmentCalendar, sectionHasAssignments, externalItems);
      expect(result).toBeFalsy();
    });

    it('returns false when copy IAC is checked', () => {
      const assignmentCalendar = { copyIgc: false, copyIac: true };
      const sectionHasAssignments = false;
      const externalItems = ['item1', 'item2'];

      const result = learningTrackData.showSelectCourseMsg(assignmentCalendar, sectionHasAssignments, externalItems);
      expect(result).toBeFalsy();
    });

    it('returns false when no external items exist', () => {
      const assignmentCalendar = { copyIgc: false, copyIac: false };
      const sectionHasAssignments = false;
      const externalItems = [];

      const result = learningTrackData.showSelectCourseMsg(assignmentCalendar, sectionHasAssignments, externalItems);
      expect(result).toBeFalsy();
    });
  });
});
