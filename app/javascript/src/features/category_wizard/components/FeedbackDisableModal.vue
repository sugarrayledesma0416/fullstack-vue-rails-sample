<template>
  <div class="enhanced-feedback-modal" :class="testClass('enhanced-feedback-modal')">
    <ModalComponent
      :hideHeader="true"
      @close="$emit('close', $event)">
      <template #body>
        <div :class="testClass('feedback-disable-warning')">
          Are you sure? This will make it harder for students to see
          why their responses are incorrect.
        </div>
      </template>
      <template #footer>
        <div class="enhanced-feedback-modal-controls">
          <VhlButton
            variant="primary"
            :class="testClass('confirm-btn')"
            @click="$emit('close', $event)">
            OK
          </VhlButton>
        </div>
      </template>
    </ModalComponent>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import ModalComponent from 'features/modal/ModalComponent';
  import VhlButton from 'features/learning_tracks/components/VhlButton';

  export default {
    name: 'FeedbackDisableModal',
    components: { ModalComponent, VhlButton },
    emits: ['close'],
    setup() {
      return { testClass };
    },
  };
</script>

<style scoped>
  .enhanced-feedback-modal-controls {
    display: flex;
    justify-content: center;
  }
</style>
