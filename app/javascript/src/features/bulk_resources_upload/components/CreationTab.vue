<template>
  <sl-details ref='disclosureRef' :disabled="!allValidationsPassed" :open="allValidationsPassed"
    summary="Creation process"
    :class="[{ 'border-color-success': allValidationsPassed }, 'c-card  l-col-12  creation-sl-details  common-styles']">
    <div class="l-grid  u-mar-lt-2  sl-details__content__l-grid">
      <div class="l-col-4  c-card  u-bord-top-10  u-bord-radius-10  u-bg-gray-e  u-mar-rt-2">
        <h5>Creation:</h5>
        <div class="c-button-group  c-button-group--lt">
          <p>Here you'll be able to start the creation process.</p>
          <button class="c-button  c-button--primary  test-bulk-creation-start-button" @click="startCreation">
            Start Creation
          </button>
        </div>
      </div>
      <div class="l-col-7  c-card  u-bord-radius-10  u-bg-gray-e">
        <h5>Creation information:</h5>
        <table class="c-table  u-mar-top-4  bulk-irs-table  test-bulk-creation-status-table">
          <thead>
            <tr class="c-header-row">
              <th scope="col">Step</th>
              <th scope="col">Message</th>
              <th scope="col">Time</th>
            </tr>
          </thead>
          <tbody>
            <template v-if="creationInformationAvailable">
              <tr v-for="(log, index) in safeLogs" :key="index" class="c-row">
                <td>{{ log.key }}</td>
                <td>{{ log.message }}</td>
                <td>{{ log.time }}</td>
              </tr>
            </template>
            <tr v-else class="c-row">
              <td colspan="3">No creation in progress</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </sl-details>
</template>

<script setup>
  import { postToEndpoint } from 'music';
  import { ref, computed } from 'vue';

  const props = defineProps({ 
    rootUrl:{ 
      type: String,
      required: true
    },
    allValidationsPassed:{ 
      type: Boolean,
      required: true
    },
    creationTrackerInformation:{
      type: Object,
      required: true
    }
  });
  const emit = defineEmits(['showEmit', 'startCreation', 'creationStatusChanged']);
  const disclosureRef = ref(null);
  
  /**
   * Checks if creation information is available and valid
   * @param {Object} creationTrackerInformation - The creation tracker information object
   * @returns {Boolean} - True if creation information is available and valid
   */
  function isCreationInformationAvailable(creationTrackerInformation) {
    return creationTrackerInformation &&
           creationTrackerInformation.logs &&
           Array.isArray(creationTrackerInformation.logs) &&
           creationTrackerInformation.logs.length > 0 &&
           (creationTrackerInformation.state === 'completed' || creationTrackerInformation.state === 'failed');
  }

  const creationInformationAvailable = computed(() => {
    return isCreationInformationAvailable(props.creationTrackerInformation);
  });

  const safeLogs = computed(() => {
    return props.creationTrackerInformation?.logs || [];
  });

  /**
  * Initiates the creation process by sending a request to the server.
  * Emits a success message when the process is started.
  */
  async function startCreation(){
    emit('creationStatusChanged', true);
    postToEndpoint(
      `${props.rootUrl}/start_creation`,
      {},
      (response) => {
        emit('showEmit', {message: 'Creation process started.', type: 'success'});
        emit('startCreation');
      }
    );
  }
</script>

<style lang="scss" scoped>
@import 'MusicAssets/stylesheets/music/library/v1/base/main';

.sl-details__content__l-grid {
  display: flex;
  justify-content: space-around;
}

:deep(sl-details::part(header)) {
  background-color: var(--music-true-gray-50);
}

.bulk-irs-table th,
.bulk-irs-table td {
  text-align: center;
}

.border-color-success {
  border-color: var(--music-util-success);
}

.creation-sl-details {
  margin-bottom: rpx(16);
}

.common-styles {
  font-size: rpx(14);
  background-color: var(--music-true-gray-50);
  border-style: solid;
  border-left-width: rpx(10);
  border-right-width: rpx(10);
  border-radius: rpx(10);
}
</style>
