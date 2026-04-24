<template>
  <div>
    <teleport
      v-for="activity in activityData"
      :key="activity.id"
      :to="`#share_activity_${activity.id}`"
    >
      <a
        v-if="!activity.draft"
        :id="`js-share-id-${activity.id}`"
        :key="activity.id"
        class="menu__link"
        href="#"
        @click="toggleShare(activity.id, activity.shared)">
        Share
      </a>
    </teleport>
    <ShareActivityModal
      v-if="localData.showShareActivityModal"
      :activityID="localData.activityID"
      :programID="programID"
      :isShared="localData.isShared"
      :defaultSelect="localData.defaultSelect"
      :shareAction="localData.shareAction"
      :disabledUpdateButton="localData.disabledUpdateButton"
      @close="closeModal()"
      @confirm="toggleShare()"
      @change="updateAction($event)" />
  </div>
</template>

<script setup>
  import ShareActivityModal from './components/ShareActivityModal.vue';
  import { reactive } from 'vue';

  const props = defineProps({
    activityData: {
      type: Array,
      required: true,
    },
    programID: {
      type: String,
      required: true,
    },
  });

  const localData = reactive({
    showShareActivityModal: false,
    activityID: '',
    isShared: false,
    shareAction: 'share',
    defaultSelect: 'share',
    disabledUpdateButton: true,
  });

  /**
  * Shows the manage share modal and initializes the default select value,
  * button state, submit endpoint, and action for the form.
  * @param { string } activityID
  * @param { string } shared - Current share status of the activity.
  */
  function toggleShare(activityID, shared) {
    localData.activityID = activityID;
    localData.showShareActivityModal = true;
    localData.defaultSelect = shared ? 'share' : 'set_private';
    localData.isShared = shared;
  }

  /**
  * Updates the form action when the select element changes between
  * 'share' and 'set_private'.
  */
  function updateAction(event) {
    if (event.target.value == 'share') {
      localData.shareAction = 'share';
    } else {
      localData.shareAction = 'set_private';
    }
    updateButtonState();
  }

  /**
  * Disables the submit button if the sharing
  * action selected matches the current sharing status of the activity.
  */
  function updateButtonState() {
    const actionIsShare = localData.shareAction == 'share';
    if (actionIsShare == localData.isShared) {
      localData.disabledUpdateButton = true;
    } else {
      localData.disabledUpdateButton = false;
    }
  }

  function closeModal() {
    localData.showShareActivityModal = false;
  };
</script>
