import * as ajaxUtils from 'shared/ajax_utils';

/**
 *  Monitor the status of Sidekiq workers.
 */
class Monitor {
  /**
   * Set up the configutation required for initializing
   * Monitor.
   * @constructor
   * @param {string} jobId - Id of job to monitor.
   */
  constructor(jobId) {
    this.jobId = jobId;
  }

  /**
   * Returns a promise that resolve to the status
   * of the job.
   * @return {Promise} - promise that resolve to the status.
   */
  status() {
    const url = '/workers/' + this.jobId;
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

export default Monitor;
