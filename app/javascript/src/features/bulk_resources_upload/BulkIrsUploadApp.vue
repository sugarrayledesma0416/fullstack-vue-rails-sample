<template>
  <sl-dialog ref="dialogRef" label="Delete confirmation" class="dialog-overview  test-delete-confirmation-modal">
    <p>This action will permanently delete all the resources for this book. Are you sure?</p>
    <l-spanner-v3 class="delete-resources-buttons-container">
      <sl-button slot="footer" @click="dialogRef?.hide()" variant="primary">Cancel</sl-button>
      <sl-button slot="footer" @click="deleteResources()" variant="danger"
        class="bulk-delete-confirm-button">Delete</sl-button>
    </l-spanner-v3>
  </sl-dialog>

  <FlashMessages :showEmit='showEmit' />

  <div class="irs-steps-accordion  l-col-10">

    <UploadFilesTab 
      :class="testClass('upload-files-tab')" 
      :presignedUrl="presignedUrl" 
      :rootUrl="rootUrl"
      :isCreationInProgress="isCreationInProgress" 
      @preventReload="setPreventReload" 
      @uploadsReady="readyForValidations"
      @showEmit="onShowEmit" 
      @creationStatusChanged="handleCreationStatusChange"/>

    <ValidationTab 
      :class="testClass('validation-tab')" 
      ref="validationTabRef" 
      :rootUrl="rootUrl"
      :isCreationInProgress="isCreationInProgress" 
      @preventReload="setPreventReload"
      @allValidationsPassed="onAllValidationsPassed" 
      @showEmit="onShowEmit"/>

    <CreationTab 
      :rootUrl="rootUrl" 
      :allValidationsPassed="allValidationsPassed" 
      @showEmit="onShowEmit"
      :creationTrackerInformation="creationTrackerInformation"
      :class="testClass('creation-tab')" 
      @startCreation="onStartCreation"/>

  </div>

  <div class="c-button-group  c-button-group--lt">
    <sl-button :disabled="!allValidationsPassed || isCreationInProgress" class='delete-resources-button'
      @click="dialogRef?.show()" variant="danger">Delete resources</sl-button>
    <div v-show="deleting">
      <sl-spinner class="spinner-md"></sl-spinner>
    </div>

    <div v-show="isCreationInProgress" class="c-button-group  c-button-group--lt  u-mar-top-4">
      <button class="c-button-v3  c-button-v3--tertiary" @click="dialogRef?.show()">
        View Last Creation
      </button>
    </div>

    <sl-alert variant="danger" open closable v-show="deleteNotCompleted">
      <sl-icon slot="icon" name="x-circle"></sl-icon>
      We were not able to delete all the resources, perform this action again.
    </sl-alert>
  </div>

  <div v-if="isCreationInProgress" class="blur-overlay  test-bulk-upload-blur-screen">
    <div class="overlay-message">
      <div
        v-if="!safeLogs.length || safeState === 'completed'"
        class="spinner-container">
        <sl-spinner class="spinner-lg"></sl-spinner>
        <p class="test-bulk-creation-status-table-loading-text">Loading creation status...</p>
      </div>
      <table v-else class="c-table  bulk-irs-table  test-bulk-creation-status-table">
        <thead>
          <tr class="c-header-row">
            <th scope="col">Step</th>
            <th scope="col">Message</th>
            <th scope="col">Time</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(log, index) in safeLogs" :key="index" class="c-row">
            <td>{{ log.key }}</td>
            <td>{{ log.message }}</td>
            <td>{{ log.time }}</td>
          </tr>
        </tbody>
      </table>
        <div class="progress-bar-container">
          <sl-progress-bar :value="safeProgress"></sl-progress-bar>
        </div>
    </div>
  </div>
</template>

<script setup>
  import { ref, onMounted, onBeforeUnmount, computed } from 'vue';
  import { postToEndpoint, testClass } from 'music';
  import UploadFilesTab from './components/UploadFilesTab.vue';
  import ValidationTab from './components/ValidationTab.vue';
  import CreationTab from './components/CreationTab.vue';
  import FlashMessages from './components/FlashMessages.vue';
  import { checkCreationInProgress } from './utilities/creation_helper';

  const props = defineProps({
    presignedUrl: {
      type: String,
      required: true,
    },
    rootUrl: {
      type: String,
      required: true,
    },
  });
  const deleting = ref(false);  
  const preventReload = ref(false);
  const showEmit = ref({});
  const allValidationsPassed = ref(false);
  const validationTabRef = ref(null);
  const dialogRef = ref(null);
  const deleteNotCompleted = ref(false);
  const isCreationInProgress = ref(false);
  const creationTrackerInformation = ref({
    logs: [],
    state: '',
    progress: 0
  });
  const pollingInterval = ref(null);
  const NO_CONTENT = 204;
  let listenerAdded = false;

  // Computed properties for safe access to creationTrackerInformation
  const safeLogs = computed(() => {
    return creationTrackerInformation.value.logs;
  });

  const safeState = computed(() => {
    return creationTrackerInformation.value.state;
  });

  const safeProgress = computed(() => {
    return creationTrackerInformation.value.progress;
  });

  /**
   * Handles creation status changes from child components
   * @param {boolean} status - The new creation status
   */
  function handleCreationStatusChange(status) {
    isCreationInProgress.value = status;
    if (status) {
      startPollingCreationStatus();
    } else {
      stopPollingCreationStatus();
    }
  }

  /**
   * Starts polling for creation status every 5 seconds until no process is in progress
   */
  function startPollingCreationStatus() {
    if (pollingInterval.value) return;
    
    pollingInterval.value = setInterval(async () => {
      try {
        const response = await checkCreationInProgress(props.rootUrl);
        
        creationTrackerInformation.value = {
          logs: response.logs || [],
          state: response.state || '',
          progress: response.progress || 0
        };
        
        if (!response.creation_in_progress) {
          handleCreationStatusChange(false);
        }
      } catch (error) {
        console.error('Error checking creation status:', error);
        onShowEmit({message: 'An error occurred while checking the creation status.', type: 'error'});
        handleCreationStatusChange(false);
      }
    }, 5000);
  }

  /**
   * Stops the polling interval if it exists and refreshes the page
   */
  function stopPollingCreationStatus() {
    if (pollingInterval.value) {
      clearInterval(pollingInterval.value);
      pollingInterval.value = null;
    }
  }

  /**
   * Handles the start of a creation process
   */
  function onStartCreation() {
    handleCreationStatusChange(true);
  }

  // Cleanup polling interval when component is unmounted
  onBeforeUnmount(() => {
    stopPollingCreationStatus();
  });

  /**
  * Ensures only one <sl-details> is open in .irs-steps-accordion.
  * Closes others on sl-show. Warns if container not found.
  *
  * @see https://shoelace.style/components/details
  */
  onMounted(() => {
    const container = document.querySelector('.irs-steps-accordion');
    if (container) {
      container.addEventListener('sl-show', event => {
        if (event.target.localName === 'sl-details') {
          [...container.querySelectorAll('sl-details')].forEach(details => {
            details.open = event.target === details;
          });
        }
      });
    } else {
      console.warn('.c-accordion-example not found.');
    }
  });
  /**
  * Toggles the preventReload flag to block or allow page reloads.
  * Used to avoid data loss while a critical task is in progress.
  *
  * @param {boolean} state - Whether to enable or disable reload prevention.
  */
  function setPreventReload(state) {
    if (state === true && !preventReload.value) {
      preventReload.value = true;
    } else if (state === false && preventReload.value) {
      preventReload.value = false;
    }
  }
  /**
  * Triggers validations after files are successfully uploaded.
  * Resets validation state before starting the process.
  */
  async function readyForValidations() {
    allValidationsPassed.value = false;
    await validationTabRef.value.startValidations();
  }

  function onAllValidationsPassed() {
    allValidationsPassed.value = true;
  }
  /**
  * Emits errors and notices to be displayed by the FlashMessages component.
  * Alerts are shown on screen for 6 seconds.
  *
  * @param {Object} payload - The message payload containing error or notice details.
  */
  function onShowEmit(payload){
    showEmit.value = { status: true, payload }
    setTimeout(() => {
      showEmit.value.status = false;
    }, 6000)
  }
  /**
  * Initiates the resource deletion process by making a request to the server.
  * Displays success or error messages based on the response. Prevents page reload during the process.
  */
  async function deleteResources(){
    deleting.value = true;
    dialogRef.value.hide();
    setPreventReload(true);
    deleteNotCompleted.value = false;
    postToEndpoint(
      `${props.rootUrl}/bulk_delete`,
      {},
      (response) => {
        if(response.status == NO_CONTENT){
          onShowEmit({message: 'Resources deleted.', type: 'success'});
        } else {
          onShowEmit({message: "We were not able to delete all the resources, perform this action again.", type: 'error'});
          deleteNotCompleted.value = true;
        }
        deleting.value = false;
        setPreventReload(false);
      }
    );
  }
  /**
  * Handles the 'beforeunload' event to prevent page reload if a critical task is in progress.
  * Cancels the reload when preventReload is set to true.
  *
  * @param {Event} event - The beforeunload event object.
  */
  function handleBeforeUnload(event) {
    if (preventReload.value) {
      event.preventDefault();
      return '';
    }
  }
 /**
 * Adds the `beforeunload` listener after a user gesture (click).
 * Prevents reload only after user interaction, complying with browser policies.
 */
  function enableBeforeUnload() {
    if (!listenerAdded) {
      window.addEventListener('beforeunload', handleBeforeUnload);
      listenerAdded = true;
    }
  }
  /**
  * Registers a one-time `click` listener to trigger `beforeunload` setup.
  */
  onMounted(() => {
    window.addEventListener('click', enableBeforeUnload, { once: true });
  });
  /**
  * Cleans up all event listeners on component unmount.
  */
  onBeforeUnmount(() => {
    if (listenerAdded) {
      window.removeEventListener('beforeunload', handleBeforeUnload);
    }
    window.removeEventListener('click', enableBeforeUnload);
  });
</script>

<style lang="scss" scoped>
@import 'MusicAssets/stylesheets/music/library/v1/base/main';

.delete-resources-buttons-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
}

.irs-steps-accordion sl-details:not(:last-of-type) {
  margin-bottom: var(--sl-spacing-large);
}

sl-details::part(header) {
  background-color: var(--music-true-gray-50);
}

.spinner-md {
  font-size: rpx(32);
}

.dialog-overview {
  --width: rpx(400);
}

.blur-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(rpx(5));
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.overlay-message {
  background: white;
  padding: rpx(20);
  border-radius: rpx(10);
  box-shadow: 0 0 rpx(10) rgba(0, 0, 0, 0.1);
  text-align: center;
  max-width: 80%;
  max-height: 80vh;
  overflow-y: auto;
}

.bulk-irs-table {
  width: 100%;
  margin: 0;
  
  th, td {
    padding: rpx(10);
    text-align: left;
    border-bottom: rpx(1) solid var(--music-true-gray-200);
  }

  th {
    background-color: var(--music-true-gray-50);
    font-weight: bold;
  }

  tr:last-child td {
    border-bottom: none;
  }
}

.spinner-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: rpx(16);
  
  p {
    margin: 0;
    color: var(--music-true-gray-700);
    font-size: rpx(16);
  }
}

.spinner-lg {
  font-size: rpx(48);
  color: var(--music-true-gray-700);
}
</style>
