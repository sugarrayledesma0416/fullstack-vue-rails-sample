<template>
  <BasicDialog
    :isConfirmationDialog="false"
    :isModal="true"
    title="Manual Assignment Ordering"
    @close-dialog="store.cancelCustomOrderChange">
    <template #body>
      <div class="custom-order-confirmation-dialog__body">
        If you manually reorder an assignment, you will need to manually
        order all future additions to that set.
      </div>
    </template>
    <template #footer>
      <div class="custom-order-confirmation-dialog__controls-container">
        <div class="custom-order-confirmation-dialog__remember_setting">
          <input
            id="confirmation_remember"
            v-model="store.skipConfirmations"
            class="js-dialog-a11y__first-focus-elm"
            type="checkbox">
          <label for="confirmation_remember">
            Don't ask me again
          </label>
        </div>
        <div class="custom-order-confirmation-dialog__buttons">
          <StandardButton
            @click="store.cancelCustomOrderChange">
            cancel
          </StandardButton>
          <StandardButton
            variant="primary"
            class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
            @click="store.confirmCustomOrderChange">
            continue
          </StandardButton>
        </div>
      </div>
    </template>
  </BasicDialog>
</template>

<script setup>
  import { StandardButton } from 'music';
  import BasicDialog from
  'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';
  import useAssignmentSetStore from './models/use_assignment_set_store';

  const store = useAssignmentSetStore();
</script>

<style scoped lang="sass">
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .custom-order-confirmation-dialog {
    &__remember_setting,
    &__body {
      color: $gray-3;
    }

    &__controls-container {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      justify-content: space-between;
      row-gap: 0.5rem;
    }

    &__buttons {
      column-gap: 1rem;
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      row-gap: 0.5rem;
    }
  }
</style>
