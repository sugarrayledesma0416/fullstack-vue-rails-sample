import { setActivePinia, createPinia } from 'pinia';
import useQuestionReportStore from 'features/ai/instructor_grading/suggestion_rating_reports/models/question_report_store';
import StudentResponse from 'features/ai/instructor_grading/suggestion_rating_reports/models/student_response';
import * as ajaxUtils from 'shared/ajax_utils';

jest.mock('shared/ajax_utils');
jest.mock('features/ai/instructor_grading/suggestion_rating_reports/models/student_response');

describe('QuestionReportStore', () => {
  let store;
  let consoleSpy;

  beforeEach(() => {
    setActivePinia(createPinia());
    store = useQuestionReportStore();
    consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.clearAllMocks();
  });

  afterEach(() => {
    consoleSpy.mockRestore();
  });

  describe('init', () => {
    const mockData = {
      ratingCategories: ['category1', 'category2'],
      studentResponses: [{ id: 1 }, { id: 2 }],
      loadMoreUrl: 'next-page-url',
      gradingSuggestionPrompts: ['prompt1'],
      overallCommentPrompts: ['comment1'],
      options: { option1: true }
    };

    it('initializes store with provided data', () => {
      store.init(mockData);

      expect(StudentResponse).toHaveBeenCalledTimes(2);
      expect(store.ratingCategories).toEqual(mockData.ratingCategories);
      expect(store.gradingSuggestionPrompts).toEqual(mockData.gradingSuggestionPrompts);
      expect(store.overallCommentPrompts).toEqual(mockData.overallCommentPrompts);
      expect(store.loadMoreUrl).toBe(mockData.loadMoreUrl);
      expect(store.options).toEqual(mockData.options);
    });
  });

  describe('selectPage', () => {
    beforeEach(() => {
      store.studentResponses = [
        { id: 1 },
        { id: 2 },
        { id: 3 }
      ];
    });

    it('selects an existing page', () => {
      store.selectPage(2);
      expect(store.currentPage).toBe(2);
      expect(store.currentPageInput).toEqual({ id: 2 });
    });

    it('loads more data when selecting last page', () => {
      store.loadMoreUrl = 'next-url';
      store.selectPage(3);
      expect(ajaxUtils.getFromEndpoint).toHaveBeenCalled();
    });

    it('does not load more data when no more pages available', () => {
      store.loadMoreUrl = null;
      store.selectPage(3);
      expect(ajaxUtils.getFromEndpoint).not.toHaveBeenCalled();
    });
  });

  describe('loadMoreStudentResponses', () => {
    const mockResponse = {
      nextUrl: 'new-next-url',
      entries: [{ id: 4 }, { id: 5 }]
    };

    beforeEach(() => {
      store.loadMoreUrl = 'current-url';
      store.ratingCategories = ['category1'];
      store.gradingSuggestionPrompts = ['prompt1'];
      store.overallCommentPrompts = ['comment1'];
      store.studentResponses = [{ id: 1 }, { id: 2 }, { id: 3 }];
    });

    it('loads more student responses successfully', () => {
      ajaxUtils.getFromEndpoint.mockImplementation((url, callback) => {
        callback(mockResponse);
      });

      return store.loadMoreStudentResponses().then(() => {
        expect(store.loadMoreUrl).toBe('new-next-url');
        expect(store.loadingMoreData).toBe(false);
        expect(StudentResponse).toHaveBeenCalledTimes(2);
      });
    });

    it('handles error response', () => {
      ajaxUtils.getFromEndpoint.mockImplementation((url, callback) => {
        callback({ errors: ['Error'] });
      });

      return store.loadMoreStudentResponses().then(() => {
        expect(store.loadingMoreData).toBe(false);
        expect(consoleSpy).toHaveBeenCalledWith('Failed to load more results:', ['Error']);
      });
    });

    it('handles network error', () => {
      ajaxUtils.getFromEndpoint.mockImplementation(() => {
        throw new Error('Network error');
      });

      return store.loadMoreStudentResponses().then(() => {
        expect(store.loadingMoreData).toBe(false);
        expect(consoleSpy).toHaveBeenCalledWith('Failed to load more results:', expect.any(Error));
      });
    });
  });
});
