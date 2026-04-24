import Monitor from 'features/learning_tracks/models/monitor';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

describe('Monitor', () => {
  const jobId = 1;
  const url = `/workers/${jobId}`;

  let monitor;

  describe('#status', () => {
    beforeEach(
      () => {
        spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
        fetchMock.mock(
          url, { status: 200, body: { data: { status: 'complete' }}}
        );
        monitor = new Monitor(jobId);
        monitor.status();
      }
    );

    afterEach(() => fetchMock.restore());

    it('makes a call to fetch job status', () => {
      expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
        url, jasmine.any(Function)
      );
    });
  });
});
