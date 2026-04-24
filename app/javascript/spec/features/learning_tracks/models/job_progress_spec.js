import JobProgress from 'features/learning_tracks/models/job_progress';
import { dispatchCustomEvent } from 'shared/utils';

let jobProgress;
const errorCallback = jest.fn();

describe('JobProgress', () => {
  describe('#constructor', () => {
    beforeEach(() => {
      jobProgress = new JobProgress(errorCallback);
    });

    it('has value to show progress bar as false', () => {
      expect(jobProgress.shouldShow).toBe(false);
    });

    it('has value of jobIds as an empty array', () => {
      expect(jobProgress.jobIds).toEqual([]);
    });

    it('has value of isJobComplete as false', () => {
      expect(jobProgress.isJobComplete).toBeFalsy();
    });
  });

  describe('when onJobFailed is called', () => {
    beforeEach(() => {
      jobProgress.onJobFailed();
    });

    it('calls error callback ', () => {
      expect(errorCallback).toHaveBeenCalled();
    });
  });

  describe('when onJobFinished is called', () => {
    beforeEach(() => {
      jobProgress.onJobFinished();
    });

    it('sets isJobComplete flag as true', () => {
      expect(jobProgress.isJobComplete).toBe(true);
    });
  });
});
