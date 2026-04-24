import {
  acceptOverallComment,
  removeOverallComment,
  setupOverallCommentInterop } from 'features/ai/instructor_grading_sets/lib/overall_comment';

const mockComment = 'This is a default comment.';
let mockDOM;
let mockOverallComment;

describe('acceptOverallComment', () => {
  beforeEach(() => {
    mockOverallComment = {
      accept: jest.fn(),
      defaultComment: mockComment,
      edited: false,
      remove: jest.fn(),
      validateEdit: jest.fn(),
    };

    mockDOM = new DOMParser().parseFromString(
      '<textarea id="comment"></textarea>', 'text/html');
  });

  describe('#acceptOverallComment', () => {
    it('Does not call the accept method of the overall comment.', () => {
      acceptOverallComment(mockOverallComment, 'comment', { DOM: mockDOM });
      expect(mockOverallComment.accept).not.toHaveBeenCalled();
    });

    it('Fires the callback when provided.', () => {
      const callback = jest.fn();
      const options = { callback, DOM: mockDOM };
      acceptOverallComment(mockOverallComment, 'comment', options);
      expect(callback).toHaveBeenCalled();
    });

    it('Does not change the comment if the default comment is already present.', () => {
      mockDOM.getElementById('comment').value = mockComment;
      acceptOverallComment(mockOverallComment, 'comment', { DOM: mockDOM });
      expect(mockDOM.getElementById('comment').value).toBe(mockComment);
    });

    it('Keeps the user comment if it already contains the default comment.', () => {
      const comment = mockComment + ' And this is an addition.';
      const element = mockDOM.getElementById('comment');
      const expected = comment;
      element.value = comment;
      
      acceptOverallComment(mockOverallComment, 'comment', { DOM: mockDOM });
      expect(element.value).toBe(expected);
    });
  });

  describe('#removeOverallComment', () => {
    it('Does not call the remove method of the overall comment.', () => {
      removeOverallComment(mockOverallComment, 'comment', { DOM: mockDOM });
      expect(mockOverallComment.remove).not.toHaveBeenCalled();
    });

    it('Fires the callback when provided.', () => {
      const callback = jest.fn();
      const options = { callback, DOM: mockDOM };
      removeOverallComment(mockOverallComment, 'comment', options);
      expect(callback).toHaveBeenCalled();
    });

    it('Does not change the comment if the default comment is already present.', () => {
      const comment = 'This is a default comment';
      mockDOM.getElementById('comment').value = comment;
      removeOverallComment(mockOverallComment, 'comment', { DOM: mockDOM });
      expect(mockDOM.getElementById('comment').value).toBe(comment);
    });

    it('Removes the default comment from the user comment.', () => {
      const comment = mockComment + ' And this is an addition.';
      const element = mockDOM.getElementById('comment');
      element.value = comment;
      removeOverallComment(mockOverallComment, 'comment', { DOM: mockDOM });
      expect(element.value).toBe(' And this is an addition.');
    });
  });

  describe('#setupOverallCommentInterop', () => {
    it('Validates an edit when the user edits the overall comment text area.', () => {
      const element = mockDOM.getElementById('comment');
      element.value = 'This is a different comment.';
      mockOverallComment.accepted = true;
      setupOverallCommentInterop(mockOverallComment, 'comment', { DOM: mockDOM });
      element.dispatchEvent(new Event('input'));
      expect(mockOverallComment.validateEdit).toHaveBeenCalled();
    });

    it('Is a no-op if the overall comment is not accepted.', () => {
      const element = mockDOM.getElementById('comment');
      setupOverallCommentInterop(mockOverallComment, 'comment', { DOM: mockDOM });
      element.dispatchEvent(new Event('input'));
      expect(mockOverallComment.validateEdit).not.toHaveBeenCalled();
    });
  });
});
