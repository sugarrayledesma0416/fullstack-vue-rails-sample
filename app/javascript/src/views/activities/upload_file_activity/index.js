import { mountVueAppOnElms } from 'shared/utils/vue';
import { UploadFileActivityApp } from 'mae';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElms(UploadFileActivityApp, '.js-upload-file-activity-app');
});
