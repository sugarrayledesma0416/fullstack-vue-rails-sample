<template>
  <sl-details ref='disclosureRef' summary="Validation process."
    :class="[borderClass, 'c-card  l-col-12  validation-sl-details  common-styles']">
    <div class="l-grid  u-mar-lt-2  sl-details__content__l-grid">
      <div :class="['l-col-4  c-card  u-bord-top-10  u-bg-gray-e  u-mar-rt-2', borderClass]">
        <h5>Validation result:</h5>
        <div class="c-button-group  c-button-group--lt">
          <table v-show="!loadingValidations"
            class="c-table  u-mar-top-4  test-bulk-validation-status-table-summary  bulk-irs-table">
            <thead>
              <tr class="c-header-row">
                <th scope="col">Issues</th>
                <th scope="col">Number</th>
              </tr>
            </thead>
            <tbody>
              <tr class="c-row">
                <th scope="row">Errors</th>
                <td>{{ errorsNumber }}</td>
              </tr>
              <tr class="c-row">
                <th scope="row">Warnings</th>
                <td>{{ warningsNumber }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="u-txt-ctr" v-show="loadingValidations">
          <sl-spinner class="spinner-lg"></sl-spinner>
        </div>
      </div>

      <div class="l-col-7  c-card  u-bg-gray-e  u-mar-rt-2">
        <table v-show="loadingValidations" class="c-table  u-mar-top-4  bulk-irs-table  validation-loading-table">
          <thead>
            <tr class="c-header-row">
              <th scope="row">Error type</th>
              <th scope="row">Number</th>
              <th scope="row">Message</th>
            </tr>
          </thead>
          <tbody>
            <tr class="c-row">
              <th><sl-spinner class="spinner-md"></sl-spinner></th>
              <td><sl-spinner class="spinner-md"></sl-spinner></td>
              <td><sl-spinner class="spinner-md"></sl-spinner></td>
            </tr>
          </tbody>
        </table>

        <table v-show="!loadingValidations"
          class="c-table  u-mar-top-4  test-bulk-validation-status-table  bulk-irs-table  validation-results-table">
          <thead>
            <tr class="c-header-row">
              <th scope="row">Error</th>
              <th scope="row">Occurrences</th>
              <th scope="row">Message</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(data, type) in errorsBreakdown" :key="type" class="c-row">
              <td>{{ type }}</td>
              <td>{{ data.size }}</td>
              <td>{{ data.message }}</td>
            </tr>
          </tbody>
        </table>
        <button class="c-button  c-button--secondary  u-bord-1"
          :disabled="errorsNumber === 0 && warningsNumber == 0 || errorsNumber == null" @click="downloadErrorsReport">
          Download report
        </button>
      </div>
    </div>
  </sl-details>
</template>

<script setup>
  import { ref, computed } from 'vue';
  import { postToEndpoint, getFromEndpoint, getCsvFile } from 'music';

  const props = defineProps({
    rootUrl:{
      type: String,
      required: true
    },
  });

  const emit = defineEmits(['allValidationsPassed', 'showEmit', 'preventReload']);
  const loadingValidations = ref(false);
  const errorsNumber = ref(null);  
  const warningsNumber = ref(null);  
  const errorsBreakdown = ref({});
  const allValidationsPassed = ref(false);
  const disclosureRef = ref(null);
  const csvFileName = ref('errors_report.csv');
  /**
  * Computes the border class based on validation states.
  * Returns different classes for error, warning, or success based on the validation results.
  *
  * @returns {string} CSS class for border styling.
  */
  const borderClass = computed(() => {
    if (errorsNumber.value > 0) return 'border-color-error';
    if (warningsNumber.value > 0 && errorsNumber.value === 0) return 'border-color-warning';
    if (allValidationsPassed.value && warningsNumber.value === 0) return 'border-color-success';
    return '';
  })
  /**
  * Starts the validation process, resetting the state and showing loading indicators.
  * Emits an error message if validation fails.
  */
  async function startValidations() {
    resetValidationState();
    emit('preventReload', true);
    disclosureRef.value.show();
    loadingValidations.value = true;
    try {
      await runValidations();
    } catch (error) {
      emit('showEmit', {message: 'Validation failed.', type: 'error'});
    } finally {
      loadingValidations.value = false;
      emit('preventReload', false);
    }
  }
  /**
  * Resets the validation state by clearing errors, warnings, and other related data.
  */
  function resetValidationState() {
    errorsNumber.value = null;
    warningsNumber.value = null;
    errorsBreakdown.value = {};
    allValidationsPassed.value = false;
  }
  /**
  * Runs validations by sending a request to the server and processing the response.
  * Emits success or error messages based on the validation result.
  *
  * @returns {Promise<void>} Resolves on completion, rejects on error.
  */
  function runValidations() {
    return new Promise((resolve, reject) => {
      postToEndpoint(
        `${props.rootUrl}/validate`,
        {},
        (response) => {
          try {
            errorsNumber.value = response.errors_number;
            warningsNumber.value = response.warnings_number;
            errorsBreakdown.value = response.errors_breakdown;
            csvFileName.value = response.csv_file_name;
            if (response.errors_number === 0) {
              allValidationsPassed.value = true;
              emit('allValidationsPassed');
              emit('showEmit', {message: 'Validations passed', type: 'success'});
            }else {
              emit('showEmit', {message: 'Errors found, for further information download the errors report.', type: 'error'});
            }
            resolve();
          } catch (e) {
            reject(e);
          }
        }
      );
    });
  }
  /**
  * Downloads the bulk errors report as a CSV file.
  * Fetches the report from the server and triggers the download.
  */
  async function downloadErrorsReport() {
    await getCsvFile(`${props.rootUrl}/download_errors_report`, csvFileName.value);
  }

  defineExpose({ startValidations });
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

.spinner-md {
  font-size: rpx(32);
}

.spinner-lg {
  font-size: rpx(48);
}

.bulk-irs-table th,
.bulk-irs-table td {
  text-align: center;
}

.validation-loading-table {
  width: 100%;
}

.validation-results-table {
  width: 100%;
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

.border-color-success {
  border-color: var(--music-util-success);
}

.border-color-error {
  border-color: var(--music-util-error);
}

.border-color-warning {
  border-color: var(--music-util-warning);
}
</style>
