<template>
  <BasicDialog
    :isConfirmationDialog="false"
    :isModal="true"
    title="Default Order"
    @close-dialog="store.cancelDefaultOrderChange">
    <template #body>
      <div class="default-order-confirmation-dialog__body">
        <p>
          Are you sure you want to switch to default order?
        </p>

        <p>
          All changes to the custom order will be deleted and the assignments
          will return to their original order.
        </p>

        <p class="default-order-confirmation-dialog__warning-text">
          This action cannot be undone.
        </p>
      </div>
    </template>
    <template #footer>
      <div class="default-order-confirmation-dialog__controls-container">
        <div class="default-order-confirmation-dialog__buttons">
          <StandardButton
            @click="store.cancelDefaultOrderChange">
            cancel
          </StandardButton>
          <StandardButton
            variant="primary"
            class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
            @click="store.confirmDefaultOrderChange">
            confirm
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

  .default-order-confirmation-dialog {
    &__body {
      color: $gray-3;
    }

    &__warning-text {
      color: $danger;
      font-weight: bold;
    }

    &__controls-container {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      justify-content: flex-end;
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
