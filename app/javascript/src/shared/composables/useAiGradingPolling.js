import { ref } from 'vue';
import * as ajaxUtils from 'shared/ajax_utils';

export function useAiGradingPolling({ activityId, programId, sectionId, onSuccess, onFailure, maxAttempts = 15 }) {
  const status = ref('processing');
  const pollingAttempts = ref(0);
  const isCheckingStatus = ref(false);
  const pollingInterval = ref(null);
  const lastCheckTime = ref(null);
  const MIN_CHECK_INTERVAL = 1000;

  function stopPolling() {
    if (pollingInterval.value) {
      clearInterval(pollingInterval.value);
      pollingInterval.value = null;
    }
  }

  async function checkGradingStatus() {
    if (isCheckingStatus.value || !activityId || !programId || !sectionId) return;
    if (lastCheckTime.value && Date.now() - lastCheckTime.value < MIN_CHECK_INTERVAL) return;
    if (pollingAttempts.value >= maxAttempts) {
      stopPolling();
      onSuccess?.();
      return;
    }

    const params = new URLSearchParams({
      activity_id: activityId,
      program_id: programId,
      section_id: sectionId,
    });

    try {
      isCheckingStatus.value = true;
      pollingAttempts.value += 1;
      lastCheckTime.value = Date.now();

      const response = await fetch(`/instructor/grading_tasks/grading_status?${params.toString()}`);
      if (!response.ok) throw new Error(`HTTP error! Status: ${response.status}`);
      const data = await response.json();
      status.value = data.status;

      if (status.value === 'completed' || status.value === 'ready' || status.value === 'failed') {
        stopPolling();
        onSuccess?.();
      }
    } catch (error) {
      console.error('Polling error:', error);
    } finally {
      isCheckingStatus.value = false;
    }
  }

  function startPolling() {
    if (!pollingInterval.value) {
      pollingInterval.value = setInterval(checkGradingStatus, 2000);
    }
  }

  function startAIFeedback({ onStartSuccess, onStartError }) {
    const params = { activity_id: activityId, program_id: programId, section_id: sectionId };

    ajaxUtils.postToEndpoint(
      "/instructor/grading_tasks/start_ai_feedback",
      params,
      (data) => {
        onStartSuccess?.(data.grading_set_id);
        startPolling();
      },
      (error) => {
        console.error("Error starting grading:", error);
        onStartError?.(error);
      }
    );
  }

  return {
    status,
    startAIFeedback,
    startPolling,
    stopPolling,
    checkGradingStatus,
    pollingAttempts,
    isCheckingStatus,
  };
}
