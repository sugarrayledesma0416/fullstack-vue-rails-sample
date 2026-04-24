import { reactive } from 'vue';
import Monitor from './monitor';

/** Class for Job Progress Model. */
class JobProgress {
  /**
   * Initialize reactive object which stores progress bar state
   * @constructor
   * @param {Function} errorCallback - Function to be called when job is failed.
   */
  constructor(errorCallback) {
    this.progressBar = reactive({
      shouldShow: false,
      jobIds: [],
      isJobComplete: false,
      monitors: [],
    });
    this.errorCallback = errorCallback;
  }

  /**
   * returns the jobIds array.
   * @return {string[]}
   */
  get jobIds() {
    return this.progressBar.jobIds;
  }

  /**
   * Sets the jobIds array and monitors array.
   * @param {string[]} value - Value of jobIds.
   */
  set jobIds(value) {
    this.progressBar.jobIds = value;
    if (value) {
      this.progressBar.monitors = value.map((jobId) => {
        return new Monitor(jobId);
      });
    }
  }

  /**
   * returns the value of isJobComplete.
   * @return {boolean}
   */
  get isJobComplete() {
    return this.progressBar.isJobComplete;
  }

  /**
   * Get whether to show progress bar.
   * @return {boolean}
   */
  get shouldShow() {
    return this.progressBar.shouldShow;
  }

  /**
   * Set whether to show progress bar.
   * @param {boolean} value - Whether to show progress bar.
   */
  set shouldShow(value) {
    this.progressBar.shouldShow = value;
  }

  /**
   * returns the monitors array.
   * @return {MonitorObject[]}
   */
  get monitors() {
    return this.progressBar.monitors;
  }

  /**
   * Sets the monitors array.
   * @param {MonitorObject[]} value
   */
  set monitors(value) {
    this.progressBar.monitors = value;
  }

  /**
   * This calls the errorCallback on job failed.
   */
  onJobFailed() {
    this.shouldShow = false;
    this.errorCallback();
  }

  /**
   * This sets the isJobComplete to true.
   */
  onJobFinished() {
    this.progressBar.isJobComplete = true;
  }

  /**
   * @typedef { Object } progressUpdateObject
   * @property { number } value
   * @property { string } label
   * @property { number } startingValue
   * @property { boolean } completed
   */

  /**
   * Async - Get progress on curent jobs.
   * @param { number } startingValue
   * @return { progressUpdateObject }
   */
  async updateProgress(startingValue) {
    const jobMultiplier = (1/this.monitors.length).toFixed(2);
    const completedProgressValue = jobMultiplier * 100 * this.monitors.length;
    let label = '';
    let value = startingValue;
    let newStartingValue = 0;

    await Promise.all(
      this.monitors.map(async (monitor, index) => {
        if (this.isJobComplete) return;

        const response = await monitor.status();
        if (response.at !== undefined) {
          value += parseInt(response.at) * jobMultiplier;

          // If a job has completed, increase the startingValue and move to the next monitor
          if (response.completed) {
            newStartingValue += value;
            return;
          }
          label = value + '%';
        }

        if (response.completed) {
          return;
        }

        if (response.status === 'failed') {
          this.onJobFailed();
          return;
        }

        if (value >= completedProgressValue) {
          this.onJobFinished();
          value = 100;
          label = '100%';
        }
      })
    );
    return { value: value, label: label, startingValue: newStartingValue };
  }
}

export default JobProgress;
