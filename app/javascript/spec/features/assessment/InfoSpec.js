import { shallowMount } from '@vue/test-utils';
import AssessmentDetails from 'features/assessment/components/AssessmentDetails.vue';
import Info from 'features/assessment/Info.vue';
import PasswordScreen from 'features/assessment/components/PasswordScreen.vue';

let wrapper;

function getWrapper(props) {
  return shallowMount(Info, { props });
}

describe('Info.vue', () => {
  let props;

  beforeEach(() => {
    props = {
      assessmentTimeLimit: '60 minutes',
      beginAssessmentUrl: '/begin-assessment-url',
      pretestType: 'audio',
      icons: 'icon-string',
      isTimedAssessment: 'true',
      questionSummary: 'summary-string',
      requestPath: '/request-path',
      requireUnlocking: 'true',
      returnUrl: '/return-url',
      rules: 'rules-string',
    };
  });

  describe('when unlocking is required and assessment detail not visible', () => {
    beforeEach(() => {
      props.requireUnlocking = 'true';
      wrapper = getWrapper(props);
    });

    it('renders PasswordScreen component', () => {
      expect(wrapper.findComponent(PasswordScreen).exists()).toBeTruthy();
    });

    it('does not render AssessmentDetails component', () => {
      expect(wrapper.findComponent(AssessmentDetails).exists()).toBeFalsy();
    });

    it('passes the correct props to PasswordScreen', () => {
      const passwordScreen = wrapper.findComponent(PasswordScreen);
      expect(passwordScreen.props().requestPath).toBe(props.requestPath);
    });

    it('passes the correct returnUrl to PasswordScreen', () => {
      const passwordScreen = wrapper.findComponent(PasswordScreen);
      expect(passwordScreen.props().returnUrl).toBe(props.returnUrl);
    });

    it('updates localStore to show AssessmentDetails page on unlock-assessment event ' +
      'with false as event data', async () => {
      await wrapper.findComponent(PasswordScreen).vm.$emit('unlock-assessment', false);
      expect(wrapper.vm.localStore.currentAppStep).toBe('ASSESSMENT_DETAIL');
    });
  });

  describe('when unlocking is not required and assessment detail is visible', () => {
    beforeEach(() => {
      props.requireUnlocking = 'false';
      wrapper = getWrapper(props);
    });

    it('does not render PasswordScreen component', () => {
      expect(wrapper.findComponent(PasswordScreen).exists()).toBeFalsy();
    });

    it('renders AssessmentDetails component', () => {
      expect(wrapper.findComponent(AssessmentDetails).exists()).toBeTruthy();
    });

    it('passes the correct isTimedAssessment prop to AssessmentDetails', () => {
      const assessmentDetails = wrapper.findComponent(AssessmentDetails);
      expect(assessmentDetails.props().isTimedAssessment).toBeTruthy();
    });

    it('passes the correct assessmentTimeLimit to AssessmentDetails', () => {
      const assessmentDetails = wrapper.findComponent(AssessmentDetails);
      expect(assessmentDetails.props().assessmentTimeLimit).toBe(props.assessmentTimeLimit);
    });

    it('passes the correct rules to AssessmentDetails', () => {
      const assessmentDetails = wrapper.findComponent(AssessmentDetails);
      expect(assessmentDetails.props().rules).toBe(props.rules);
    });

    it('passes the correct icons to AssessmentDetails', () => {
      const assessmentDetails = wrapper.findComponent(AssessmentDetails);
      expect(assessmentDetails.props().icons).toBe(props.icons);
    });

    it('passes the correct questionSummary to AssessmentDetails', () => {
      const assessmentDetails = wrapper.findComponent(AssessmentDetails);
      expect(assessmentDetails.props().questionSummary).toBe(props.questionSummary);
    });
  });

  describe('when showPretest is false', () => {
    beforeEach(() => {
      wrapper = getWrapper(props);
      wrapper.vm.localStore.currentAppStep = 'ASSESSMENT_DETAIL';
      wrapper.vm.localStore.showPretest = false;
    });

    it('renders AssessmentDetails component', () => {
      expect(wrapper.findComponent(AssessmentDetails).exists()).toBeTruthy();
    });

    it('does not render PretestApp component', () => {
      expect(wrapper.findComponent({ name: 'PretestApp' }).exists()).toBeFalsy();
    });
  });

  describe('when showPretest is changed to true', () => {
    describe('when hideBackgroundScreen is false', () => {
      beforeEach(() => {
        wrapper = getWrapper(props);
        wrapper.vm.localStore.currentAppStep = 'ASSESSMENT_DETAIL';
        wrapper.vm.localStore.showPretest = true;
        wrapper.vm.localStore.hideBackgroundScreen = false;
      });

      it('does not render PasswordScreen component', () => {
        expect(wrapper.findComponent(PasswordScreen).exists()).toBeFalsy();
      });

      it('renders AssessmentDetails component', () => {
        expect(wrapper.findComponent(AssessmentDetails).exists()).toBeTruthy();
      });

      it('renders PretestApp component', () => {
        expect(wrapper.findComponent({ name: 'PretestApp' }).exists()).toBeTruthy();
      });
    });

    describe('when hideBackgroundScreen is true', () => {
      beforeEach(() => {
        wrapper = getWrapper(props);
        wrapper.vm.localStore.currentAppStep = 'ASSESSMENT_DETAIL';
        wrapper.vm.localStore.showPretest = true;
        wrapper.vm.localStore.hideBackgroundScreen = true;
      });

      it('does not render PasswordScreen component', () => {
        expect(wrapper.findComponent(PasswordScreen).exists()).toBeFalsy();
      });

      it('does not render AssessmentDetails component', () => {
        expect(wrapper.findComponent(AssessmentDetails).exists()).toBeFalsy();
      });

      it('renders PretestApp component', () => {
        expect(wrapper.findComponent({ name: 'PretestApp' }).exists()).toBeTruthy();
      });
    });
  });
});
