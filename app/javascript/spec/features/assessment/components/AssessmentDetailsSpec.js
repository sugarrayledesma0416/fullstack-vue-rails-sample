import { mount } from '@vue/test-utils';
import { redirectToUrl } from 'shared/utils.js';
import AssessmentDetails from 'features/assessment/components/AssessmentDetails.vue';
import QuestionDetails from 'features/assessment/components/QuestionDetails.vue';
import Requirements from 'features/assessment/components/Requirements.vue';
import Rules from 'features/assessment/components/Rules.vue';

jest.mock('shared/utils.js', () => ({
  redirectToUrl: jest.fn(),
}));

let wrapper;

function getWrapper(props) {
  return mount(AssessmentDetails, { props });
}

describe('AssessmentDetails', () => {
  let props;

  beforeEach(() => {
    props = {
      assessmentTimeLimit: '60 minutes',
      icons: 'solo_video_recording,audio',
      isTimedAssessment: true,
      isSupersiteJr: false,
      pretestType: 'video',
      questionSummary: '{"fill_in_the_blanks":20,"solo_video_recording":1}',
      rules: '[{"text":"accents","status":false}]',
      beginAssessmentUrl: '/sections/123/activities/456?begin_work=true',
    };
  });

  describe('when isTimedAssessment is true', () => {
    beforeEach(() => {
      wrapper = getWrapper(props);
    });

    it('renders the assessment time limit information', () => {
      expect(wrapper.find('.test-assessment-info-timed').exists()).toBeTruthy();
    });

    it('displays the correct assessment time limit', () => {
      expect(
        wrapper.find('.test-assessment-info-bold').text()
      ).toBe('You have 60 minutes to complete this assessment.');
    });

    it('contains a horizontal rule after the time limit information', () => {
      expect(wrapper.find('hr').exists()).toBeTruthy();
    });
  });

  describe('when isTimedAssessment is false', () => {
    beforeEach(() => {
      props.isTimedAssessment = false;
      wrapper = getWrapper(props);
    });

    it('does not render the assessment time limit information', () => {
      expect(wrapper.find('.test-assessment-info-timed').exists()).toBeFalsy();
    });
  });

  describe('QuestionDetails component', () => {
    beforeEach(() => {
      wrapper = getWrapper(props);
    });

    it('renders QuestionDetails component', () => {
      expect(wrapper.findComponent(QuestionDetails).exists()).toBeTruthy();
    });

    it('passes the correct questionSummary prop to QuestionDetails', () => {
      const questionDetails = wrapper.findComponent(QuestionDetails);
      expect(questionDetails.props().questionSummary).toBe(props.questionSummary);
    });
  });

  describe('Requirements component', () => {
    describe('when hasValidRequirement is true', () => {
      beforeEach(() => {
        wrapper = getWrapper(props);
      });

      it('renders Requirements component', () => {
        expect(wrapper.findComponent(Requirements).exists()).toBeTruthy();
      });

      it('passes the correct icons prop to Requirements', () => {
        const requirements = wrapper.findComponent(Requirements);
        expect(requirements.props().icons).toBe(props.icons);
      });
    });

    describe('when hasValidRequirement is false', () => {
      beforeEach(() => {
        props.icons = 'invalid_icon';
        wrapper = getWrapper(props);
      });

      it('does not render Requirements component', () => {
        expect(wrapper.findComponent(Requirements).exists()).toBeFalsy();
      });
    });
  });

  describe('Rules component', () => {
    beforeEach(() => {
      wrapper = getWrapper(props);
    });

    it('renders Rules component', () => {
      expect(wrapper.findComponent(Rules).exists()).toBeTruthy();
    });

    it('passes the correct rules prop to Rules', () => {
      const rulesComponent = wrapper.findComponent(Rules);
      expect(rulesComponent.props().rules).toBe(props.rules);
    });
  });

  describe('when assessment contains solo_video_recording', () => {
    let testConnectionButton;

    beforeEach(() => {
      wrapper = getWrapper(props);
      testConnectionButton = wrapper.find('.test-pre-test-connection');
    });

    it('renders Test Connection Button', () => {
      expect(testConnectionButton.exists()).toBeTruthy();
    });

    it('does not renders Begin Assessment Button', () => {
      const beginAssessmentButton = wrapper.find('.test-assessment-start-btn');
      expect(beginAssessmentButton.exists()).toBeFalsy();
    });

    it('emits start-pre-test event when Test Connection button is clicked', async () => {
      await testConnectionButton.trigger('click');

      expect(wrapper.emitted()['start-pre-test']).toBeTruthy();
    });
  });

  describe('when assessment does not contain either audio or video pretestType.', () => {
    let beginAssessmentButton;

    beforeEach(() => {
      props.pretestType = '';
      wrapper = getWrapper(props);
      beginAssessmentButton = wrapper.find('.test-assessment-start-btn');
    });

    it('renders assessment start button with text "Begin Assessment"', () => {
      expect(beginAssessmentButton.text()).toBe('Begin Assessment');
    });

    it('does not renders Test Connection Button', () => {
      const testConnectionButton = wrapper.find('.test-pre-test-connection');
      expect(testConnectionButton.exists()).toBeFalsy();
    });

    it(
      'calls redirectToUrl with beginAssessmentUrl when Begin Assessment button is clicked',
      async () => {
        await beginAssessmentButton.trigger('click');
        expect(redirectToUrl).toHaveBeenCalledWith(props.beginAssessmentUrl);
      }
    );
  });

  describe('when assessment contains audio pretestType.', () => {
    let testConnectionButton;

    beforeEach(() => {
      props.pretestType = 'audio';
      wrapper = getWrapper(props);
      testConnectionButton = wrapper.find('.test-pre-test-connection');
    });

    it('renders Test Connection Button', () => {
      expect(testConnectionButton.exists()).toBeTruthy();
    });

    it('emits start-pre-test event when Test Connection button is clicked', async () => {
      await testConnectionButton.trigger('click');

      expect(wrapper.emitted()['start-pre-test']).toBeTruthy();
    });
  });

  describe('when supersite junior UI is rendered', () => {
    beforeEach(() => {
      props.isSupersiteJr = true;
      wrapper = getWrapper(props);
    });

    it('renders assessment start button with text "Start"', () => {
      expect(wrapper.find('.test-assessment-start-btn').text()).toBe('Start');
    });

    it('does not renders pre test connection button', () => {
      expect(wrapper.find('.test-pre-test-connection').exists()).toBeFalsy();
    });
  });
});
