<template>
  <div id="grading_style_form_container" :class="{ 'ns-ai-grading-sets': aiFeedbackEnabled }">
    <form @submit.prevent="submitGradingStyle" id="grading_style_form" name="grading_style_form">
      <h3>How would you like to grade?</h3>
      <div id="grading_style_options">
        <div class="grading_style_forms u-dis-flex ns-music-v1" style="gap: 10px;">
          <div class="grading-option  u-dis-flex">
            <input
              type="radio"
              id="grading_style_student_by_student"
              name="grading_style"
              :value="'student_by_student'"
              :checked="gradingStyle === 'student_by_student'"
              @change="handleGradingStyleChange('student_by_student')"
              class="grading_style"
            />
            <label for="grading_style_student_by_student">
              Student by student
            </label>
          </div>

          <template v-if="!smartBook && !cartridge && !hideQuestionByQuestionInput">
            <div class="grading-option  u-dis-flex">
              <input
                type="radio"
                id="grading_style_question_by_question"
                name="grading_style"
                :value="'question_by_question'"
                :checked="gradingStyle === 'question_by_question'"
                @change="handleGradingStyleChange('question_by_question')"
                class="grading_style"
                :disabled="qByQDisabled"
              />
              <label for="grading_style_question_by_question">
                Question by question
              </label>
              <span v-if="qByQDisabled" :title="qByQDisabledMsg">
                <InfoBlueIcon />
              </span>
            </div>
          </template>

          <template v-if="!smartBook && !cartridge">
            <div class="grading-option  u-dis-flex">
              <input
                type="radio"
                id="grading_style_spotcheck"
                name="grading_style"
                :value="'spotcheck'"
                :checked="gradingStyle === 'spotcheck'"
                @change="handleGradingStyleChange('spotcheck')"
                class="grading_style"
                :disabled="activityGroupChat"
              />
              <label for="grading_style_spotcheck">
                Spotcheck Student Work
              </label>
              <span v-if="activityGroupChat" title="Group Chats can only be graded student by student.">
                <InfoBlueIcon />
              </span>
            </div>
          </template>

        </div>
      </div>

      <div v-if="aiFeedbackEnabled">
        <div class="u-dis-flex" style="gap: 8px;">
          <h3 class="u-mar-top-10">Use AI-assisted feedback?</h3>
          <span class="u-mar-top-10" title="Artificial intelligence will suggest feedback to students' work which can be edited or removed by you. This is an experimental feature. We welcome your feedback!">
            <InfoBlueIcon />
          </span>
        </div>
        <div class="c-ai-feedback-options  u-dis-flex  flex-justify-between  flex-align-ctr  u-pad-top-10" style="gap: 10px;">
          <input
            type="radio"
            id="enable_ai_grading_no"
            name="enableAiGrading"
            :value="false"
            :checked="!enableAiGrading"
            @change="handleAiGradingChange(false)"
          />
          <label class="u-pad-0" for="enable_ai_grading_no">No</label>

          <input
            type="radio"
            id="enable_ai_grading_yes"
            name="enableAiGrading"
            :value="true"
            :checked="enableAiGrading"
            @change="handleAiGradingChange(true)"
          />
          <label class="u-pad-0" for="enable_ai_grading_yes">Yes</label>

          <button
            :title="props.gradingSetButtonText"
            class="c-button c-button--primary c-button--low"
            style="margin-left: auto;"
            type="submit">
            {{ gradingSetButtonText }}
          </button>
        </div>
      </div>
      <div class="u-dis-flex" v-else>
        <button
          :title="props.gradingSetButtonText"
          class="c-button c-button--primary c-button--low"
          style="margin-left: auto;"
          type="submit">
          {{ gradingSetButtonText }}
        </button>
      </div>
      <GradingModal
        :show="showModal"
        :error-message="modalErrorMessage"
        @close="closeModal"
      />
    </form>

  </div>
</template>

<script setup>
  import { ref, watch, onMounted, onUnmounted } from 'vue';
  import * as ajaxUtils from 'shared/ajax_utils';
  import { useAiGradingPolling } from 'shared/composables/useAiGradingPolling';
  import GradingModal from 'shared/grading/GradingModal.vue';
  import InfoBlueIcon from './components/InfoBlueIcon.vue';

  const props = defineProps({
    activityId: Number,
    programId: Number,
    sectionId: Number,
    aiFeedbackEnabled: Boolean,
    qByQDisabled: Boolean,
    qByQDisabledMsg: String,
    activityGroupChat: Boolean,
    smartBook: Boolean,
    cartridge: Boolean,
    taskType: String,
    hideQuestionByQuestionInput: Boolean,
    aiGradingSuggestionsEnabled: Boolean,
    gradingStyle: String,
    gradingSetButtonText: String,
  });

  const gradingStyle = ref(props.gradingStyle);
  const enableAiGrading = ref(props.aiGradingSuggestionsEnabled);
  const previousState = ref({
    gradingStyle: props.gradingStyle,
    enableAiGrading: props.aiGradingSuggestionsEnabled
  });

  const gradingSetId = ref(null);
  const showModal = ref(false);
  const modalErrorMessage = ref(null);

  const {
    status,
    startAIFeedback,
    startPolling,
    stopPolling,
    checkGradingStatus
  } = useAiGradingPolling({
    activityId: props.activityId,
    programId: props.programId,
    sectionId: props.sectionId,
    onSuccess: () => {
      showModal.value = false;
      redirectToGradingPage();
    },
    onFailure: (error) => {
      console.error("AI grading failed:", error);
      showModal.value = false;
    }
  });

  /**
   * Handles form submission for grading style selection.
   * - Retrieves or creates a grading set.
   * - Starts polling for AI grading status if AI grading is enabled.
   * - Redirects to the grading page once grading is ready.
   * @returns {Promise<void>}
   */
  const submitGradingStyle = async () => {
    try {
      gradingSetId.value = await getOrCreateGradingSet();
    } catch (error) {
      console.error("Error creating grading set:", error);
      modalErrorMessage.value = error?.message || 'An unexpected error occurred.';
      return;
    }

    if (!enableAiGrading.value) {
      redirectToGradingPage();
      return;
    }

    await checkGradingStatus();

    if (status.value === "ready") {
      redirectToGradingPage();
      return;
    }

    showModal.value = true;

    if (!props.aiFeedbackEnabled) return;

    startAIFeedback({
      onStartSuccess: (gradingSet) => {
        gradingSetId.value = gradingSet;
      },
      onStartError: (error) => {
        console.error("Error starting grading:", error);
        showModal.value = false;
      }
    });
  };

  /**
   * Retrieves or creates a grading set.
   * @returns {Promise<string>} The ID of the grading set.
   */
  const getOrCreateGradingSet = async () => {
    const params = {
      activity_id: props.activityId,
      program_id: props.programId,
      section_id: props.sectionId,
      task_type: props.taskType
    };

    return new Promise((resolve, reject) => {
      ajaxUtils.postToEndpoint(
        "/instructor/grading_tasks/find_or_create_grading_set_id",
        params,
        (data) => {
          if (data.error) {
            modalErrorMessage.value = data.error;
          }
          resolve(data.grading_set_id);
        },
        (error) => {
          modalErrorMessage.value = error?.message || 'An unexpected error occurred.';
          reject(new Error(error?.message || 'An unexpected error occurred.'));
        }
      );
    });
  };

  /**
   * Redirects to the grading page based on the grading style.
   */
  const redirectToGradingPage = () => {
    let location;
    if (gradingStyle.value === 'spotcheck') {
      location = `/instructor/to_do/${props.programId}/activity/${props.activityId}?task_type=${props.taskType}`;
    } else {
      location = `/instructor/${props.programId}/grading_sets/${gradingSetId.value}/edit?task_type=${props.taskType}`;
    }
    window.location.href = location;
  };

  /**
   * Updates the grading style and AI grading preferences in the backend
   */
  const updateGradingStyle = (force = false) => {
    if (!force &&
        previousState.value.gradingStyle === gradingStyle.value &&
        previousState.value.enableAiGrading === enableAiGrading.value) {
      return;
    }

    const params = {
      instructor: {
        grading_style: gradingStyle.value,
        enable_ai_grading_suggestions: `${enableAiGrading.value}`,
      },
      program_id: props.programId,
    };

    ajaxUtils.putToEndpoint(
      `/instructor/${props.programId}/grading_styles/update`,
      { instructor: params.instructor, program_id: props.programId },
      () => {
        previousState.value = {
          gradingStyle: gradingStyle.value,
          enableAiGrading: enableAiGrading.value
        };
      },
      (error) => {
        gradingStyle.value = previousState.value.gradingStyle;
        enableAiGrading.value = previousState.value.enableAiGrading;
      }
    );
  };

  // Handles changes in grading style
  const handleGradingStyleChange = (value) => {
    gradingStyle.value = value;
    updateGradingStyle(true);
  };

  const handleAiGradingChange = (value) => {
    enableAiGrading.value = value;
    updateGradingStyle(true);
  };

  // Watch for changes in values (as a backup)
  watch([gradingStyle, enableAiGrading], () => {
    updateGradingStyle();
  });

  const handlePopState = () => {
    updateGradingStyle(true);
  };

  onMounted(() => {
    hideTaskSections();
    window.addEventListener('popstate', handlePopState);
  });

  onUnmounted(() => {
    stopPolling();
    window.removeEventListener('popstate', handlePopState);
  });

  const hideTaskSections = () => {
    const currentTask = 'needs_grading_section';
    document.querySelectorAll('div[id$="_section"]').forEach((section) => {
      section.classList.add('hidden_helper');
    });

    const selectedSection = document.getElementById(currentTask);
    if (selectedSection) {
      selectedSection.classList.remove('hidden_helper');
    }
  };
</script>

<style scoped>
  #grading_style_form_container {
    background: radial-gradient(circle at 80% -50%, #f8c7b9, #fcdfcd, #faffe5, #e1f6ef);
    border-radius: 0.5rem;
    padding: 1rem;
  }

  .grading-option {
    align-items: center;
    gap: 4px;
  }
</style>
