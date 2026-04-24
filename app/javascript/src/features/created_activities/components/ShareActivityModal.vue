<template>
  <BasicDialog
    :isConfirmationDialog="true"
    :isModal="true"
    title="Share Activity">
    <template #body>
      <h2 class="u-txt-red  u-txt-18">Manage Sharing</h2>
      <hr class="u-mar-top-16  u-mar-bot-16">
      <div class="share-activity-message  u-mar-bot-32">
        Control viewing and copying of this content for all instructors in your <br> program and institution.
      </div>
      <BasicSelect
        id="share-selector"
        :options="optionsArray"
        testSelector="share-selector"
        :modelValue="defaultSelect"
        @change="$emit('change', $event)"
        theme="vol" />
    </template>
    <template #footer>
      <form :action="submitURL" method="post">
        <div class="m4-button-group--space-between">
          <input type="hidden" name="authenticity_token" :value="csrfToken">
          <StandardButton
            id="cancel-button"
            class="u-bord-solid  u-bord-1  m4-button--round  u-bord-gray-6  u-txt-gray-6  u-mar-rt-8"
            @click="$emit('close', $event)">
            Cancel
          </StandardButton>
          <StandardButton
            id="update-button"
            class="m4-button--primary  js-modal-a11y__default-focus  js-modal-a11y__last-focus-element"
            :disabled="disabledUpdateButton"
            type="submit">
            Update
          </StandardButton>
        </div>
      </form>
    </template>
  </BasicDialog>
</template>

<script setup>
  import { computed } from 'vue';
  import { metaTagContent  } from '../../../shared/utils';
  import { StandardButton, testClass } from 'music';
  import BasicDialog from
  'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';
  import BasicSelect from
  'music/app/javascript/src/components/basic_select/v1.2/BasicSelect.vue';

  defineEmits(['close', 'confirm', 'change']);

  const props = defineProps({
    activityID: { type: String, required: true },
    programID: { type: String, required: true },
    isShared: { type: Boolean, required: true },
    shareAction: { type: String, required: true },
    defaultSelect: { type: String, required: true },
    disabledUpdateButton: { type: Boolean, required: true },
  });
  const csrfToken = metaTagContent('csrf-token');
  const baseURL = window.location.origin;
  const submitURL = computed(() => {
    return `${baseURL}/instructor/${props.programID}/my_content/${props.activityID}/${props.shareAction}`; 
  });
  const optionsArray = [
    { text: 'Shared: Instructors can view, copy and edit their copy of this content.',
      value: 'share'
    },
    { text: 'Private: No one can view or copy this content except you.',
      value: 'set_private'
    },
  ];
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .share-activity-message {
    line-height: rpx(24);
    max-width: rpx(870);
  }
</style>
