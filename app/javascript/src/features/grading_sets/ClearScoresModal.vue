<template>
  <ModalComponent
    title="Change Grading Method"
    @close="closeModal">
    <template #body>
      <div :class="testClass('clear-scores-modal')">
        <div class="c-panel  c-panel--padded  u-mar-0">
          <div class="c-panel__body">
            <p>
              Changing the grading method will clear all previously <br>
              entered scores for this student's assignment. <br>
              Do you want to continue?
            </p>
          </div>
          <div class="c-panel__footer  l-inline-group">
            <div class="c-form-item">
              <input
                id="suppress-modal-flag"
                ref="checkbox"
                class="c-form-item__checkbox"
                type="checkbox">
              <label
                class="c-form-item__label"
                for="suppress-modal-flag">
                Don't ask me again
              </label>
            </div>
            <div class="c-button-group  u-mar-0  u-txt-rt">
              <button
                type="button"
                class="c-button"
                :class="testClass('close-modal')"
                @click="closeModal">
                Cancel
              </button>
              <button
                :class="testClass('clear-scores')"
                type="button"
                class="c-button  c-button--primary  u-txt-upper  u-bg-red"
                @click="closeModalClearScores">
                Clear Scores
              </button>
            </div>
          </div>
        </div>
      </div>
    </template>
  </ModalComponent>
</template>

<script setup>
  import ModalComponent from 'features/modal/ModalComponent';
  import { testClass } from 'music';
  import { ref } from 'vue';

  const emit = defineEmits(
    ['closeClearScoresModal', 'toggleGradingMethod']
  );

  const checkbox = ref(null);

  /**
   * Emits closeClearScoresModal event
   * with value of 'Don't ask me again' checkbox.
   */
  function closeModal() {
    emit('closeClearScoresModal', checkbox.value.checked);
  }

  /**
   * Emits closeClearScoresModal event
   * with value of 'Don't ask me again' checkbox.
   * Emits toggleGradingMethod event.
   */
  function closeModalClearScores() {
    emit('closeClearScoresModal', checkbox.value.checked);
    emit('toggleGradingMethod');
  }
</script>
