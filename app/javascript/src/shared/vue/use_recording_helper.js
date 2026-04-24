/**
 * An Instructor Notes recording. Probably audio.
 * @example <caption>Creating a URL for a legacy recording path</caption>
 * legacyPath= '/volume_2/student_attempts/2018/03/29/79c/470/ac8/da6'
 *           + '/79c470ac-8da6-4eb8-9c89-0314abd1aa64';
 * return pathToURL(legacyPath);
 * // output: 'https://arcaudio.ms.vhlcentral.com/old_arc/volume_2/student_attempts'
 *          + '/2018/03/29/79c/470/ac8/da6/79c470ac-8da6-4eb8-9c89-0314abd1aa64.wav'
 * @example <caption>Creating a URL for a recent recording path</caption>
 * recordingPath = 'instructor_notes/79c470ac-8da6-4eb8-9c89-0314abd1aa64';
 * return pathToURL(recordingPath);
 * // output: 'https://arcaudio.ms.vhlcentral.com/instructor_notes
 *          + '/79c470ac-8da6-4eb8-9c89-0314abd1aa64.wav'
 * @example <caption>Sanitizing a recent recording path for storage</caption>
 * recordingPath = 'instructor_notes/79c470ac-8da6-4eb8-9c89-0314abd1aa64.wav';
 * return sanitizePath(recordingPath);
 * // output: instructor_notes/79c470ac-8da6-4eb8-9c89-0314abd1aa64
 * @return {Object} an object wrapping following methods
 * sanitizePath,
 * pathToURL,
 */
const useRecordingHelper = () => {
  /**
   * Formats relative path for storage. File extension is
   * removed before storing so we can eventually use multiple
   * codecs.
   * @param {string} path - the relative path to the recording on the cdn
   * @return {string} - The path to store
   */
  const sanitizePath = (path) => {
    return path.replace('.wav', '');
  };

  /**
   * Creates a full path from the partial, relative path. Handles legacy paths
   *  and appending file extension.
   * @param {string} path - the relative path to the recording on the cdn
   * @return {string} - The fully qualified URL
   */
  const pathToURL = (pathconfig) => {
    // File extension is removed before storing the submission so we can
    // eventually use multiple codecs, but on disk it is a .wav.
    if (!pathconfig.recordingPath.endsWith('.wav')) {
      pathconfig.recordingPath = pathconfig.recordingPath + '.wav';
    }

    // Legacy recordings all have top-level directories in the format volume_n
    if (pathconfig.recordingPath.startsWith('/volume')) {
      const legacyBaseDir = 'old_arc'; // Legacy submissions have an initial slash
      return pathconfig.recordingCdnPrefix + legacyBaseDir + pathconfig.recordingPath;
    } else {
      return pathconfig.recordingCdnPrefix + pathconfig.recordingPath;
    }
  };

  return { sanitizePath, pathToURL };
};

export default useRecordingHelper;
