import { getUncheckedCourseIds, postToggleCoursesRequest } from 'institution_admin/dashboard/configure_view/course_toggle.js';
import { postToEndpoint } from 'shared/ajax_utils.js';
import { getSearchParam, programId } from 'shared/utils.js';

// Mock the dependencies at the top level
jest.mock('shared/ajax_utils.js', () => ({
  postToEndpoint: jest.fn()
}));

jest.mock('shared/utils.js', () => ({
  getSearchParam: jest.fn(),
  programId: jest.fn()
}));


// Reference the mocked functions
const mockPostToEndpoint = postToEndpoint;
const mockGetSearchParam = getSearchParam;
const mockProgramId = programId;

function appendElmFromString(string, destination) {
  const elm = new DOMParser()
    .parseFromString(`<div class="contents">${string}</div>`, 'text/html')
    .querySelector('.contents');
  destination.appendChild(elm);
};

describe('course toggle', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('#postToggleCoursesRequest', () => {
        it('posts data to the expected endpoint', () => {
      let ids = [1, 3, 5];
      mockGetSearchParam.mockReturnValue('106');

      let programIdValue = 42;
      mockProgramId.mockReturnValue(programIdValue);
      appendElmFromString(`<meta name="VHL.program_id" content="${programIdValue}" />`, document.head);
      let url = `${location.origin}/institution_admin/configure_view/${programIdValue}/toggle_admin_show?school_id=106`;

      postToggleCoursesRequest(ids);

      expect(mockPostToEndpoint).toHaveBeenCalledWith(url, { course_ids: ids }, expect.any(Function));
    });
  });

  describe('#getUncheckedCourseIds', () => {
    it('returns an array of ids for unchecked courses', () => {
      appendElmFromString(
        `
	<input type="checkbox" class="c-toggle  js-toggle-show" value="1">
	<input type="checkbox" class="c-toggle  js-toggle-show" value="2" checked>
	<input type="checkbox" class="c-toggle  js-toggle-show" value="3">
	<input type="checkbox" class="c-toggle  js-toggle-show" value="4" checked>
	<input type="checkbox" class="c-toggle  js-toggle-show" value="5">
	<input type="checkbox" class="c-toggle  js-toggle-show" value="6" checked>
        `,
	document.body
      );

      expect(getUncheckedCourseIds()).toEqual(['1', '3', '5']);
    });
  });
});
