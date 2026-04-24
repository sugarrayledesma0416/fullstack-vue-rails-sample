import DashboardDeepLinkForm from './dashboard_deep_link_form.js';

window.addEventListener(
  'DOMContentLoaded',
  (event) => {
    let formElm = document.querySelector('.js-create-dashboard-deep-link-form');
    const deepLinkForm = new DashboardDeepLinkForm(formElm);
  }
);
