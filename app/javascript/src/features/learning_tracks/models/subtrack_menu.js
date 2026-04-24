/** Class representing a SubtrackMenu. */
class SubtrackMenu {
  /**
   * Constructor of SubtrackMenu.
   * @param {string} trackFamilyName
   * @param {Object} learningTrack
   * @param {Array} strands
   * @param {Object} trackTabs
   */
  constructor(trackFamilyName, learningTrack, strands, trackTabs) {
    this.trackFamilyName = trackFamilyName;
    this.learningTrack = learningTrack;
    this.activities = learningTrack.activities;
    this.strands = strands;
    this.trackTabs = trackTabs;
  }

  /**
   * returns the name of the subtracks of a learning track.
   */
  get subtrackNames() {
    return Object.keys(this.learningTrack.subtracks);
  }

  /**
   * select the specific subtrack
   * @param {string} subtrackName
   * @param {number} indexOfSubtrack
   * @param {Object} learningTrackData - Object of LearningTrackDataStore class.
   * (Assignment Wizard or Course Express).
   */
  chooseSubtrack(subtrackName, indexOfSubtrack, learningTrackData) {
    const subtrack = this.learningTrack.subtracks[subtrackName];
    learningTrackData.usePredefinedTrack(
      this.trackFamilyName,
      subtrackName,
      subtrack
    );
    this.trackTabs.selectedSubtrackIndex = indexOfSubtrack;
    this.trackTabs.selectedIndex = this.trackTabs.index;
  }
}

export default SubtrackMenu;
