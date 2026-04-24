import * as ajaxUtils from 'shared/ajax_utils';

/** Class representing Learning Track HTTP */
class LearningTrackHttp {
  /**
   * Set up the configutation required for initializing LearningTrackHttp.
   * @param {number | string} programId - Id of the program.
   */
  constructor(programId) {
    this.programId = programId;
  }

  /**
   * Returns a promise that will resolve to learning tracks for a program.
   * @return {Promise} promise that resolve to learning tracks.
   */
  getTracks() {
    const url = `/instructor/${this.programId}/learning_tracks.json`;
    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        url,
        (data) => {
          resolve(data);
        }
      );
    });
  }

  /**
   * Returns a promise that will resolve to previous learning track for
   * a course`s section.
   *
   * @param {string} sectionId - Id of the section.
   * @param {string} courseId - Id of the course.
   * @return {Promise} promise that resolve to learning track.
   */
  getPreviousTrack(sectionId, courseId) {
    const queryStr = courseId ? `?current_course_id=${courseId}` : '';
    const url = `/instructor/${this.programId}/section_learning_track/` +
      `${sectionId}.json${queryStr}`;

    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        url,
        (data) => {
          resolve(data);
        }
      );
    });
  }

  /**
   * Returns the external items for the selected section
   * @param {string} sectionId - Id of the section.
   * @return {Promise} promise that resolve to external item.
   */
  getExternalItems(sectionId) {
    const url = `/instructor/learning_tracks/external_items/${sectionId}`;

    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        url,
        (data) => {
          resolve(data);
        }
      );
    });
  }
}

export default LearningTrackHttp;
