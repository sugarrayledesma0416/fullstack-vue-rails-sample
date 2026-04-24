import { createApp } from 'vue';
import GradingStyleApp from '../../../features/instructor/grading_styles/GradingStyleApp';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    const rootElm = document.querySelector('.js-grading-modal-app');
    const dataElm = document.querySelector('.js-grading-modal-data');

    if (rootElm && dataElm) {
      const dataFromDom = JSON.parse(dataElm.getAttribute('data-from-dom'));

      const app = createApp(GradingStyleApp, {
        activityId: dataFromDom.activity_id,
        programId: dataFromDom.program_id,
        sectionId: dataFromDom.section_id,
        aiFeedbackEnabled: dataFromDom.ai_feedback_enabled,
        aiGradingSuggestionsEnabled: dataFromDom.ai_grading_suggestions_enabled,
        hideQuestionByQuestionInput: dataFromDom.hide_question_by_question_input,
        gradingStyle: dataFromDom.grading_style,
        qByQDisabled: dataFromDom.q_by_q_disabled,
        qByQDisabledMsg: dataFromDom.q_by_q_disabled_msg,
        activityGroupChat: dataFromDom.activity_group_chat,
        smartBook: dataFromDom.smart_book,
        cartridge: dataFromDom.cartridge,
        taskType: dataFromDom.task_type,
        gradingSetButtonText: dataFromDom.grading_set_button_text
      });

      app.mount(rootElm);
    }
  }
);

