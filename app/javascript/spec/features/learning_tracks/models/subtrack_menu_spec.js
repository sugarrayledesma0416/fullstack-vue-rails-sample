import SubtrackMenu from 'features/learning_tracks/models/subtrack_menu';

const subtrackParams = {
  trackFamilyName: 'Fully Online',
  learningTrack: {
    description: '<b>Supports Fully Online</b>',
    rank: 1,
    subtracks: {
      Complete: { },
      Essentials: { },
    },
  },
  strands: [
    { color: '#BE0027', name: 'Contextos' },
    { color: '#76377C', name: 'Fotonovela' },
  ],
  trackTabs: { index: 0 },
};

const learningTrackData = { usePredefinedTrack: jest.fn() };

let subtrackMenu;

describe('SubtrackMenu', () => {
  describe('#initialize', () => {
    beforeEach(() => {
      subtrackMenu = new SubtrackMenu(
        subtrackParams.trackFamilyName,
        subtrackParams.learningTrack,
        subtrackParams.strands,
        subtrackParams.trackTabs
      );
    });

    it('sets the track family name', () => {
      expect(subtrackMenu.trackFamilyName).toEqual(subtrackParams.trackFamilyName);
    });

    it('sets the strands', () => {
      expect(subtrackMenu.strands).toEqual(subtrackParams.strands);
    });

    it('sets the activities as undefined', () => {
      expect(subtrackMenu.activities).toBeUndefined();
    });

    it('sets the learning track', () => {
      expect(subtrackMenu.learningTrack).toEqual(subtrackParams.learningTrack);
    });

    it('sets the trackTabs', () => {
      expect(subtrackMenu.trackTabs).toEqual(subtrackParams.trackTabs);
    });
  });

  describe('#subtrackNames', () => {
    beforeEach(() => {
      subtrackMenu = new SubtrackMenu(
        subtrackParams.trackFamilyName,
        subtrackParams.learningTrack,
        subtrackParams.strands,
        subtrackParams.trackTabs
      );
    });

    it('returns names of the subtracks', () => {
      expect(subtrackMenu.subtrackNames).toEqual(['Complete', 'Essentials']);
    });
  });

  describe('#chooseSubtrack', () => {
    beforeEach(() => {
      subtrackMenu = new SubtrackMenu(
        subtrackParams.trackFamilyName,
        subtrackParams.learningTrack,
        subtrackParams.strands,
        subtrackParams.trackTabs
      );
      subtrackMenu.chooseSubtrack(
        'Complete', 0, learningTrackData
      );
    });

    it('contains selectedSubtrackIndex in trackTabs with index as 0', () => {
      expect(subtrackMenu.trackTabs.selectedSubtrackIndex).toEqual(0);
    });

    it('contains selectedIndex in trackTabs', () => {
      expect(subtrackMenu.trackTabs.selectedIndex).toEqual(subtrackParams.trackTabs.index);
    });
  });
});
