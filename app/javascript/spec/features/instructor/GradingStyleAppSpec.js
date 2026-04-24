import { mount } from '@vue/test-utils';
import GradingStyleApp from '../../../src/features/instructor/grading_styles/GradingStyleApp';
import * as ajaxUtils from 'shared/ajax_utils';
import flushPromises from 'flush-promises';

global.fetch = jest.fn();

jest.mock('shared/ajax_utils', () => ({
  postToEndpoint: jest.fn(),
  putToEndpoint: jest.fn(),
}));

describe('GradingStyleApp.vue', () => {
  let wrapper;

  beforeEach(() => {
    delete window.location;
    window.location = { href: jest.fn() };

    global.fetch.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ status: 'ready' }),
    });

    wrapper = mount(GradingStyleApp, {
      props: {
        activityId: 1,
        programId: 2,
        sectionId: 3,
        aiFeedbackEnabled: true,
        qByQDisabled: false,
        qByQDisabledMsg: 'Disabled',
        activityGroupChat: false,
        hasRubric: true,
        aiGradingSuggestionsEnabled: true,
        gradingStyle: 'student_by_student',
      },
    });

    jest.clearAllMocks();
  });

  afterEach(() => {
    wrapper.unmount();
  });

  it('renders the component correctly', () => {
    expect(wrapper.exists()).toBe(true);
    expect(wrapper.find('h3').text()).toContain('How would you like to grade?');
    expect(wrapper.findAll('input[type="radio"]').length).toBe(5);
  });

  it('updates gradingStyle when a radio button is clicked', async () => {
    const radioButtons = wrapper.findAll('input[type="radio"]');
    await radioButtons[1].setValue('question_by_question');
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.gradingStyle).toBe('question_by_question');
  });

  it('updates enableAiGrading when AI-assisted feedback radio button is clicked', async () => {
    const aiRadioButtons = wrapper.findAll('input[name="enableAiGrading"]');

    await aiRadioButtons[0].setValue("false");
    await wrapper.vm.$nextTick();
    expect(wrapper.vm.enableAiGrading).toBe(false);

    await aiRadioButtons[1].setValue("true");
    await wrapper.vm.$nextTick();
    expect(wrapper.vm.enableAiGrading).toBe(true);
  });

  it('does not show the modal if AI grading is disabled', async () => {
    wrapper.setProps({ aiGradingSuggestionsEnabled: false });

    await flushPromises();

    expect(wrapper.find('.modal-container').exists()).toBe(false);
  });

  it('makes a POST request to start AI feedback when AI grading is enabled', async () => {
    ajaxUtils.postToEndpoint.mockImplementation((url, params, successCb) => {
      if (url.includes('find_or_create_grading_set_id')) {
        successCb({ grading_set_id: 99 });
      } else if (url.includes('start_ai_feedback')) {
        successCb({});
      }
    });

    await wrapper.vm.submitGradingStyle();

    expect(ajaxUtils.postToEndpoint).toHaveBeenCalledWith(
      '/instructor/grading_tasks/find_or_create_grading_set_id',
      expect.any(Object),
      expect.any(Function),
      expect.any(Function)
    );
  });

  it('includes task_type when calling find_or_create_grading_set_id', async () => {
    ajaxUtils.postToEndpoint.mockImplementation((url, params, successCb) => {
      if (url.includes('find_or_create_grading_set_id')) {
        successCb({ grading_set_id: 99 });
      }
    });

    await wrapper.setProps({ taskType: 'student_by_student' });
    await wrapper.vm.submitGradingStyle();

    const [url, params] = ajaxUtils.postToEndpoint.mock.calls.find(call =>
      call[0].includes('find_or_create_grading_set_id')
    );

    expect(params).toMatchObject({
      activity_id: 1,
      program_id: 2,
      section_id: 3,
      task_type: 'student_by_student'
    });
  });


  it('polls for grading status and redirects when grading is ready', async () => {
    ajaxUtils.postToEndpoint.mockImplementation((url, params, successCb) => {
      if (url.includes('find_or_create_grading_set_id')) {
        successCb({ grading_set_id: 99 });
      }
    });

    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ status: 'ready' }),
    });

    await wrapper.vm.submitGradingStyle();
    await wrapper.vm.checkGradingStatus();

    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('/instructor/grading_tasks/grading_status?')
    );
    expect(wrapper.vm.status).toBe('ready');
    expect(wrapper.vm.showModal).toBe(false);
  });

  it('handles polling failure gracefully', async () => {
    fetch.mockResolvedValueOnce({
      ok: false,
      status: 500,
    });

    await wrapper.vm.checkGradingStatus();
    expect(wrapper.vm.status).not.toBe('ready');
  });

  it('makes a PUT request when grading style is updated', async () => {
    wrapper.vm.gradingStyle = 'question_by_question';
    await wrapper.vm.updateGradingStyle();

    expect(ajaxUtils.putToEndpoint).toHaveBeenCalledWith(
      '/instructor/2/grading_styles/update',
      {
        instructor: { grading_style: 'question_by_question', enable_ai_grading_suggestions: 'true' },
        program_id: 2,
      },
      expect.any(Function),
      expect.any(Function)
    );
  });

  it('cleans up polling when component is unmounted', () => {
    const clearIntervalSpy = jest.spyOn(global, 'clearInterval');

    wrapper.vm.startPolling();
    wrapper.unmount();

    expect(clearIntervalSpy).toHaveBeenCalled();
  });
});
