import { mount } from '@vue/test-utils';
import OverallFeedback from 'features/ai/instructor_grading_sets/components/OverallFeedback';
import Suggestion from 'features/ai/instructor_grading_sets/components/Suggestion';

let wrapper;
function getWrapper(props = {}) {
  return mount(OverallFeedback, {
    props,
    global: {
      stubs: {
        Suggestion: {
          template: '<div class="test-suggestion"><slot></slot><button class="add-button" @click="onAddSuggestion">Add</button><button class="reject-button" @click="onRejectSuggestion">Reject</button></div>',
          props: ['id', 'isAdded', 'isEdited', 'onAddSuggestion', 'onRejectSuggestion']
        }
      }
    }
  });
}

describe('OverallFeedback', () => {
  const mockOverallComment = {
    id: 1,
    overallComment: 'Test feedback',
    explanation: 'Test explanation',
    accepted: false,
    edited: false,
    accept: jest.fn(),
    reject: jest.fn()
  };

  const mockOnAccept = jest.fn();
  const mockOnReject = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    wrapper = getWrapper({
      overallComment: mockOverallComment,
      onAccept: mockOnAccept,
      onReject: mockOnReject
    });
  });

  describe('when there is no feedback', () => {
    beforeEach(() => {
      wrapper = getWrapper({
        overallComment: { ...mockOverallComment, overallComment: '' },
        onAccept: mockOnAccept,
        onReject: mockOnReject
      });
    });

    it('displays the unavailable message', () => {
      expect(wrapper.find('.unavailable').exists()).toBe(true);
      expect(wrapper.find('.unavailable').text()).toBe('AI feedback is not available for this submission.');
    });

    it('does not render the Suggestion component', () => {
      expect(wrapper.findComponent(Suggestion).exists()).toBe(false);
    });
  });

  describe('when there is feedback', () => {
    it('renders the Suggestion component', () => {
      expect(wrapper.findComponent(Suggestion).exists()).toBe(true);
    });

    it('passes the correct props to Suggestion', () => {
      const suggestion = wrapper.findComponent(Suggestion);
      expect(suggestion.props()).toEqual({
        id: mockOverallComment.id,
        isAdded: false,
        isEdited: false,
        onAddSuggestion: expect.any(Function),
        onRejectSuggestion: expect.any(Function)
      });
    });

    it('displays the feedback and explanation in the Suggestion', () => {
      expect(wrapper.text()).toContain('Test feedback');
      expect(wrapper.text()).toContain('Test explanation');
    });

    describe('when feedback is accepted', () => {
      it('calls the accept method on the overall comment', async () => {
        await wrapper.find('.add-button').trigger('click');
        expect(mockOverallComment.accept).toHaveBeenCalled();
      });

      it('calls the onAccept callback', async () => {
        await wrapper.find('.add-button').trigger('click');
        expect(mockOnAccept).toHaveBeenCalled();
      });

      it('passes isAdded as true to Suggestion', () => {
        wrapper = getWrapper({
          overallComment: { ...mockOverallComment, accepted: true },
          onAccept: mockOnAccept,
          onReject: mockOnReject
        });
        expect(wrapper.findComponent(Suggestion).props('isAdded')).toBe(true);
      });
    });

    describe('when feedback is rejected', () => {
      it('calls the reject method on the overall comment', async () => {
        await wrapper.find('.reject-button').trigger('click');
        expect(mockOverallComment.reject).toHaveBeenCalled();
      });

      it('calls the onReject callback', async () => {
        await wrapper.find('.reject-button').trigger('click');
        expect(mockOnReject).toHaveBeenCalled();
      });
    });

    describe('when feedback is edited', () => {
      it('passes isEdited as true to Suggestion', () => {
        wrapper = getWrapper({
          overallComment: { ...mockOverallComment, edited: true },
          onAccept: mockOnAccept,
          onReject: mockOnReject
        });
        expect(wrapper.findComponent(Suggestion).props('isEdited')).toBe(true);
      });
    });
  });
});
