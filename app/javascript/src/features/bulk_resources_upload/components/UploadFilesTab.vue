<template>
  <sl-details open summary="Upload process."
    :class="[borderClass, 'c-card  l-col-12  uploads-sl-details  common-styles']">
    <div class="l-grid  u-mar-lt-2  sl-details__content__l-grid">
      <div :class="[borderClass, testClass('uploads-section'), 'l-col-4  c-card  u-bord-top-10  u-bg-gray-e  u-mar-rt-2']">
        <h5>Upload Zip:</h5>
        <div class="c-button-group  c-button-group--lt">
          <input class='l-col-10  test-bulk-upload-zip-input' type="file" accept=".zip" @change="onZipFileChange" />
          <div v-show="zipLoading" class="test-bulk-upload-zip-spinner">
            <sl-spinner class="spinner-md"></sl-spinner>
          </div>
        </div>

        <h5>Upload Csv:</h5>
        <div class="c-button-group  c-button-group--lt">
          <input class='l-col-10  test-bulk-upload-csv-input' type="file" accept=".csv" @change="onCsvFileChange" />
          <div v-show="csvLoading" class="test-bulk-upload-csv-spinner">
            <sl-spinner class="spinner-md"></sl-spinner>
          </div>
        </div>
      </div>

      <div :class="[testClass('status-section'), 'l-col-7  c-card  u-bg-gray-e  u-mar-lt-2']">
        <table class="c-table  test-bulk-upload-status-table  bulk-irs-table">
          <thead>
            <tr class="c-header-row">
              <th :class="testClass('upload-files-table-header')" scope="col">File</th>
              <th :class="testClass('upload-files-table-header')" scope="col">Status</th>
              <th :class="testClass('upload-files-table-header')" scope="col">Last update</th>
            </tr>
          </thead>
          <tbody>
            <tr class="c-row">
              <th :class="testClass('upload-files-table-row')" scope="row">ZIP</th>
              <td :class="testClass('upload-files-table-zip-status')">{{ s3Status.zip ? 'Uploaded' : 'Not uploaded' }}</td>
              <td>{{ s3Status.zipLastModified }}</td>
            </tr>
            <tr class="c-row">
              <th :class="testClass('upload-files-table-row')" scope="row">CSV</th>
              <td :class="testClass('upload-files-table-csv-status')">{{ s3Status.csv ? 'Uploaded' : 'Not uploaded' }}</td>
              <td>{{ s3Status.csvLastModified }}</td>
            </tr>
          </tbody>
        </table>
        <div class="c-button-group  c-button-group--lt  u-mar-top-4  u-justify-content-space-between">
          <button 
            :class="[testClass('view-last-creation-button'), 'c-button-v3  c-button-v3--tertiary']"
            @click="handleViewLastCreation">
            View Last Creation
          </button> 
          <div :class="[testClass('progress-bar-section'), 'l-col-7  u-mar-lt-2  u-mar-rt-2  u-mar-top-2']">
            <div v-if="zipLoading">
              <sl-progress-bar :class="testClass('bulk-upload-progress-bar')" :value="zipUploadProgress" label="Upload progress">
              </sl-progress-bar>
              <div class="u-mar-top-2">
                <p>Uploading ZIP: {{ zipUploadProgress }}%</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <sl-dialog ref="dialogRef" class="dialog-overview">
      <span slot="label">Last Creation Information</span>
      <div class="modal-content">
        <table class="c-table  bulk-irs-table">
          <thead>
            <tr class="c-header-row">
              <th scope="col">Step</th>
              <th scope="col">Message</th>
              <th scope="col">Time</th>
            </tr>
          </thead>
          <tbody>
            <template v-if="showLastCreationInformation">
              <tr v-for="(log, index) in lastCreationInformation.logs" :key="index" class="c-row">
                <td>{{ log.key }}</td>
                <td>{{ log.message }}</td>
                <td>{{ log.time }}</td>
              </tr>
            </template>
            <tr v-else class="c-row">
              <td colspan="3">No creation information available</td>
            </tr>
          </tbody>
        </table>
      </div>
      <button slot="footer" class="c-button-v3  c-button-v3--primary" @click="dialogRef?.hide()">Close</button>
    </sl-dialog>

    <div v-if="isCreationInProgress" class="blur-overlay">
      <div class="overlay-message">
        <p>A resource creation process is already in progress.</p>
        <p>Please wait until it completes.</p>
      </div>
    </div>
  </sl-details>
</template>

<script setup>

  import { postToEndpoint, getFromEndpoint, testClass } from 'music';
  import { ref, computed, onMounted } from 'vue';
  import { checkCreationInProgress } from '../utilities/creation_helper';

  const props = defineProps({ 
    presignedUrl:{
      type: String,
      required: true
    },
    rootUrl:{ 
      type: String,
      required: true
    },
    isCreationInProgress: {
      type: Boolean,
      required: true
    }
  });
  /**
  * Computes the border class based on the upload status.
  * Returns a success or error class depending on whether uploads are ready.
  *
  * @returns {string} CSS class for border styling.
  */
  const borderClass = computed(() => {
    if(uploadsReady.value){
      return 'border-color-success';
    } else {
      return 'border-color-error';
    }
  });

  const zipLoading = ref(false);
  const csvLoading = ref(false);
  const uploadsReady = ref(false)
  const s3Status = ref({zip: false, zipLastModified: null, csv: false, csvLastModified: null});
  const csvFile = ref(null);
  const lastCreationInformation = ref({});
  const emit = defineEmits(['uploadsReady', 'showEmit', 'preventReload', 'creationStatusChanged']);
  const dialogRef = ref(null);
  const zipUploadProgress = ref(0);
  const showLastCreationInformation = computed(() => {
    return lastCreationInformation.value && lastCreationInformation.value.logs && lastCreationInformation.value.logs.length > 0 && (lastCreationInformation.value.state === 'completed' || lastCreationInformation.value.state === 'failed');
  });

  // Check creation status on mount
  onMounted(async () => {
    lastCreationInformation.value = await checkCreationInProgress(props.rootUrl);
    emit('creationStatusChanged', lastCreationInformation.value['creation_in_progress']);
    if (!lastCreationInformation.value['creation_in_progress']) {
      checkFilesStatus();
    }
  });

  function checkFilesStatus(){
    if (!props.isCreationInProgress) {
      getFromEndpoint(
        `${props.rootUrl}/files_s3_status`,
        (response) => {
          s3Status.value.zip = response.zip;
          s3Status.value.zipLastModified = response.zip_last_modified;
          s3Status.value.csv = response.csv;
          s3Status.value.csvLastModified = response.csv_last_modified;
          if(s3Status.value.zip && s3Status.value.csv){
            uploadsReady.value = true;
            emit('uploadsReady');
          }
        }
      );
    }
  }

  async function onZipFileChange(event) {
    const progressInformation = await checkCreationInProgress(props.rootUrl);
    emit('creationStatusChanged', progressInformation['creation_in_progress']);
    
    if (progressInformation['creation_in_progress']) {
      emit('showEmit', {message: 'Cannot upload files while creation is in progress.', type: 'error'});
      event.target.value = "";
      return;
    }

    const file = event.target.files[0];
    if (!file.name.toLowerCase().endsWith(".zip")) {
      emit('showEmit', {message: 'Only ZIP files are allowed.', type: 'error'});
      event.target.value = "";
      return;
    }
    uploadZipFile(file);
    event.target.value = "";
  }

  async function onCsvFileChange(event) {
    const progressInformation = await checkCreationInProgress(props.rootUrl);
    emit('creationStatusChanged', progressInformation['creation_in_progress']);
    
    if (progressInformation['creation_in_progress']) {
      emit('showEmit', {message: 'Cannot upload files while creation is in progress.', type: 'error'});
      event.target.value = "";
      return;
    }

    const file = event.target.files[0];
    if (!file.name.toLowerCase().endsWith(".csv")) {
      emit('showEmit', {message: 'Only CSV files are allowed.', type: 'error'});
      event.target.value = "";
      return;
    }
    uploadCsvFile(file);
    event.target.value = "";
  }

  /**
  * Uploads a ZIP file and handles success or failure feedback.
  * Emits reload prevention, shows a message, and checks file status.
  *
  * @param {File} file - The ZIP file to upload.
  */
  async function uploadZipFile(file) {
    zipLoading.value = true;
    emit('preventReload', true);
    try {
      await performZipUpload(file);
      emit('showEmit', {message: 'Zip file uploaded.', type: 'success'});
      zipUploadProgress.value = 0;
      checkFilesStatus();
    } catch (error) {
      emit('showEmit', {message: 'Zip upload failed.', type: 'error'});
    } finally {
      zipLoading.value = false;
      emit('preventReload', false);
    }
  }
  /**
  * Performs a ZIP file upload using a presigned S3 URL.
  * Builds a FormData payload and sends it via a POST request.
  *
  * @param {File} file - The ZIP file to upload.
  * @returns {Promise<void>} Resolves on success, rejects on error.
  */
  function performZipUpload(file) {
    return new Promise((resolve, reject) => {
      try {
        const postUrl = JSON.parse(props.presignedUrl);
        const formData = new FormData();
        for (const key in postUrl.fields) {
          formData.append(key, postUrl.fields[key]);
        }
        formData.append('file', file);

        const xhr = new XMLHttpRequest();
        
        xhr.upload.addEventListener('progress', (event) => {
          if (event.lengthComputable) {
            const percentComplete = (event.loaded / event.total) * 100;
            zipUploadProgress.value = percentComplete.toFixed(2);
          }
        });

        xhr.addEventListener('load', () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve();
          } else {
            reject(new Error(`Upload failed with status ${xhr.status}`));
          }
        });

        xhr.addEventListener('error', () => {
          reject(new Error('Upload failed'));
        });

        xhr.open('POST', postUrl.url);
        xhr.send(formData);
      } catch (e) {
        reject(e);
      }
    });
  }
  /**
  * Uploads a CSV file, processes its content, and sends it to the server.
  * Emits success or error messages based on the upload result.
  *
  * @param {File} file - The CSV file to upload.
  */
  async function uploadCsvFile(file) {
    emit('preventReload', true);
    csvLoading.value = true;
    try {
      const response = await fetch(URL.createObjectURL(file));
      const csvContent = await response.text();
      csvFile.value = csvContent;
      await new Promise((resolve, reject) => {
        postToEndpoint(
          `${props.rootUrl}/upload_csv`,
          { csv: { content: csvFile.value, csv_file_name: file.name } },
          (result) => {
            try {
              if (result.file_uploaded) {
                emit('showEmit', {message: 'CSV file uploaded.', type: 'success'});
                checkFilesStatus();
              } else {
                emit('showEmit', {message: 'CSV Upload failed.', type: 'error'});
              }
              resolve();
            } catch (e) {
              reject(e);
            }
          }
        );
      });
    } catch (error) {
      emit('showEmit', {message: 'CSV Upload failed.', type: 'error'});
    } finally {
      csvLoading.value = false;
      emit('preventReload', false);
    }
  }

  // Function to handle opening the dialog and fetching latest data
  async function handleViewLastCreation() {
    // Fetch the latest creation information
    lastCreationInformation.value = await checkCreationInProgress(props.rootUrl);
    // Show the dialog
    dialogRef.value?.show();
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

.spinner-md {
  font-size: rpx(32);
}

.bulk-irs-table th,
.bulk-irs-table td {
  text-align: center;
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

.blur-overlay {
  position: absolute;
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
  
  p {
    margin: rpx(10) 0;
    font-size: rpx(16);
    color: var(--music-true-gray-700);
  }
}

.dialog-overview {
  --width: rpx(600);
}

.modal-content {
  padding: rpx(20);
  max-height: 60vh;
  overflow-y: auto;
}
</style>
