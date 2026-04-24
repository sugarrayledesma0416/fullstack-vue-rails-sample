import getCourseOptions from 'features/course_wizard/services/course_options_http';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

delete window.location;
window.location = new URL('http://example.com/new#/abc');
window.location.replace = jest.fn();

describe('CourseOptionsHttp', () => {
  describe('#getCourseOptions', () => {
    beforeEach(
      () => {
        spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
        fetchMock.mock(
          'http://example.com/new.json', { status: 200, body: {}}
        );
        getCourseOptions();
      }
    );

    it('removes part of the url after hash and sends a get request to fetch data', () => {
      expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
        'http://example.com/new.json',
        jasmine.any(Function)
      );
    });
  });
});
