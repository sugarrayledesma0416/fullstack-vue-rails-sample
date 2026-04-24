import { mount } from '@vue/test-utils';
import QuestionDetails from 'features/assessment/components/QuestionDetails.vue';

describe('QuestionDetails.vue', () => {
  const questionSummary = JSON.stringify({
    solo_video_recording: 1,
    tutorial_vocab: 3,
    multiple_choice: 4,
  });

  let wrapper;

  beforeEach(() => {
    wrapper = mount(QuestionDetails, {
      props: {
        questionSummary,
      },
    });
  });

  it('renders the total number of questions correctly', () => {
    const totalQuestions = wrapper.find('.test-total-question-info').text();
    expect(totalQuestions).toBe('This assessment has 8 Questions:');
  });

  it('renders the details of each question type correctly', () => {
    const details = wrapper.findAll('.test-detail-questions-info > div');
    expect(details).toHaveLength(3);
    expect(details[0].text()).toBe('1 Video Recording');
    expect(details[1].text()).toBe('3 Tutorial vocabulary');
    expect(details[2].text()).toBe('4 Multiple choice');
  });

  describe('humanizeActivityType function', () => {
    it('converts solo_video_recording to human-readable format i.e Video Recording', () => {
      expect(
        wrapper.vm.humanizeActivityType('solo_video_recording')
      ).toBe('Video Recording');
    });

    it('converts tutorial_vocab_html5 to human-readable format i.e Tutorial vocabulary', () => {
      expect(
        wrapper.vm.humanizeActivityType('tutorial_vocab_html5')
      ).toBe('Tutorial vocabulary');
    });
  });

  describe('humanize function', () => {
    it('capitalizes the first letter and replaces underscores with spaces', () => {
      expect(
        wrapper.vm.humanize('multiple_choice')
      ).toBe('Multiple choice');
    });
  });
});
