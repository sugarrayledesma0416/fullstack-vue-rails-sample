import LearningTrackHttp from './models/learning_track_http';

/**
 * This composable has methods that fetches tracks and updates the learningTrack datastore.
 * @param {Object} assignmentCalendar - AssignmentCalendar object.
 * @param {Object} config - configuration passed from the parent component i.e. either
 * assignment wizard or express course.
 * @param {Object} learningTrackData - LearningTrackData object.
 * @return {Object} - An object wrapping updateDataStore method
 */
const useLearningTrack = (assignmentCalendar, config, learningTrackData) => {
  /**
   * Update learning tracks datastore from the fetched learning tracks.
   */
  async function updateDataStore() {
    const learningTracks = await getLearningTracks();
    learningTrackData.store.learningTracks = learningTracks;
    learningTrackData.store.predefinedTracks = learningTracks;
    assignmentCalendar.activities = learningTracks.activities;
    learningTrackData.store.predefinedTrackNames = Object.keys(learningTracks.tracks);
    learningTrackData.store.allStrands = Object.values(learningTracks.strands);
  }

  /**
   * @private
   * get learning tracks.
   * @return {Object} tracks
   */
  async function getLearningTracks() {
    const learningTrackHttp = new LearningTrackHttp(config.programId);
    return await learningTrackHttp.getTracks();
  }

  return { updateDataStore };
};

export default useLearningTrack;
