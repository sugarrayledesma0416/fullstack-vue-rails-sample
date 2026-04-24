<template>
  <div v-if="store.suggestionsEnabledAtProgramLevel">
    <div class="button-container">
      <button
        type="button"
        class="button"
        :class="{ 'button--on': store.suggestionsEnabled }"
        @click="toggleSuggestions">
        <span class="button-content">
          <span class="icon">
            <ai-grading-sets-stars-icon />
          </span>
          <span class="label">Turn AI {{ store.suggestionsEnabled ? 'Off' : 'On' }}</span>
        </span>
      </button>
    </div>
    <BasicDialog
      v-if="store.showDisableSuggestionsConfirmation"
      :isConfirmationDialog="false"
      :isModal="true"
      title="Disable AI-Assisted Feedback?"
      @close-dialog="store.cancelToggleAllGradingSuggestions">
      <template #body>
        This action will remove AI-generated suggestions, and any unsaved changes
        related to AI-assisted feedback will be lost.
      </template>
      <template #footer>
        <div class="confirmation-dialog__buttons">
          <StandardButton
            class="u-mar-rt-8"
            @click="store.cancelToggleAllGradingSuggestions">
            cancel
          </StandardButton>
          <StandardButton
            variant="primary"
            class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
            @click="store.confirmToggleAllGradingSuggestions">
            disable
          </StandardButton>
        </div>
      </template>
    </BasicDialog>
  </div>
</template>

<script setup>
  import { useGradingSuggestionsStore } from './stores/grading_suggestions_store';
  import { StandardButton } from 'music';
  import BasicDialog from
  'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';

  const props = defineProps(
    {
      featureEnabledAtProgramLevel: {
        required: true,
        type: String,
      },
      featureEnabledAtUserLevel: {
        required: true,
        type: String,
      },
    }
  );

  const store = useGradingSuggestionsStore();
  store.suggestionsEnabled = props.featureEnabledAtUserLevel === 'true';
  store.suggestionsEnabledAtProgramLevel = props.featureEnabledAtProgramLevel === 'true';

  /**
   * Toggles the AI suggestions.
   */
  function toggleSuggestions() {
    store.toggleAllGradingSuggestions();
  }
</script>

<style lang="sass" scoped>
  .button {
    background: transparent;
    box-shadow: 0 0.1rem 0.2rem 0 rgba(0, 0, 0, 0.15);
    padding: 0.25rem 1rem 0.25rem 0.8rem;
    border: none;
    border-radius: 0.2rem;
    color: hsl(0, 0%, 0%);
    cursor: pointer;
    font-family: Open Sans, sans-serif;
    font-size: 1rem;
    overflow: hidden;
    position: relative;
    transition: background-position 0.2s;

    /**
     * To render the gradient background, and make it translate from left to right, we use a pseudo
     * element at 200% the width of the button, and then translate it on hover.
     */
    &::before {
      /**
       * Creating the proper hover effect prohibits us from using the --ai-grading-gradient custom
       * property, so we have to define the gradient here.
       * @see assets/stylesheets/ai/grading_sets.scss for the original gradient.
       */
      background: radial-gradient(
        circle at 0% 50%,
        #f8c7b9 -30%, #fcdfcd, #faffe5, #e1f6ef,
        #f8c7b9,      #fcdfcd, #faffe5, #e1f6ef 130%);
      content: '';
      height: 100%;
      left: -100%;
      position: absolute;
      top: 0;
      width: 200%;
      z-index: 0;
      transition: left 0.2s;

      @media (prefers-reduced-motion: reduce) {
        transition: none;
      }
    }

    &:focus, &:hover {
      &::before {
        left: 0;
      }
    }
  }

  .button--on {
    background: transparent;
    box-shadow: none;
    &::before {
      display: none;
    }

    &:hover, &:focus {
      color: hsl(0, 0%, 60%);
    }
  }

  .button-container {
    display: inline-flex;
    align-items: center;
  }

  .button-content {
    display: inline-flex;
    align-items: center;
    position: relative;
    z-index: 1;
  }

  .icon {
    display: inline-block;
    padding-right: 0.25rem;
    position: relative;
    top: 0.2rem;
    --icon-color: hsl(0, 0%, 0%);
  }
  .button--on:hover .icon, .button--on:focus .icon {
    --icon-color: hsl(0, 0%, 60%);
  }

  .label {
    display: inline-block;
    vertical-align: middle;
  }
</style>
