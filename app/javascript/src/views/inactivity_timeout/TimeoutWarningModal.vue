<template>
  <BasicDialog
    :isConfirmationDialog="true"
    :isModal="true"
    title="Session Timeout">
    <template #body>
      <div class="timeout-warning" :class="testClass('timeout-warning')">
        Please confirm you are still there.
        If not, you will be logged out in {{ textRemainingTime }}
      </div>
    </template>
    <template #footer>
      <div class="timeout-modal-controls">
        <StandardButton
          class="u-mar-rt-8"
          :class="testClass('cancel-timeout-btn')"
          @click="$emit('signout', $event)">
          Sign out
        </StandardButton>
        <StandardButton
          variant="primary"
          class="js-modal-a11y__default-focus  js-modal-a11y__last-focus-element"
          :class="testClass('confirm-timeout-btn')"
          @click="$emit('confirm', $event)">
          I'm here
        </StandardButton>
      </div>
    </template>
  </BasicDialog>
</template>

<script setup>
  import { computed } from 'vue';
  import { StandardButton, testClass } from 'music';
  import BasicDialog from
  'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';

  const props = defineProps({
    remainingTime: { required: true, type: Number },
  });

  const textRemainingTime = computed(()=>{
    const remainingTimeInMinutes = Math.ceil(props.remainingTime/60);
    return remainingTimeInMinutes > 1 ? `${remainingTimeInMinutes} minutes.` : 'a minute.';
  });

  defineEmits(['signout', 'confirm']);
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .timeout-modal-controls {
    display: flex;
    justify-content: flex-end;
  }

  .timeout-warning {
    line-height: rpx(24);
    max-width: rpx(870);
  }
</style>
