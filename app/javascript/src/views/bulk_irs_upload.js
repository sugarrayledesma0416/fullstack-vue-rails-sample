import { mountVueAppOnElm } from '../../src/shared/utils/vue';
import BulkIrsUploadApp from '../../src/features/bulk_resources_upload/BulkIrsUploadApp.vue'

document.addEventListener('DOMContentLoaded', () => {
  const bulkIrsUploadAppElm = document.querySelector('.js-bulk-irs-upload-app');

  if (bulkIrsUploadAppElm) {
    mountVueAppOnElm(BulkIrsUploadApp, '.js-bulk-irs-upload-app')
  }
});
