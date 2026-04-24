import HomePageDeepLinkForm from './home_page_deep_link_form.js';

window.addEventListener(
  'DOMContentLoaded',
  (event) => {
    let formElm = document.querySelector('.js-create-home-page-deep-link-form');
    const deepLinkForm = new HomePageDeepLinkForm(formElm);
  }
);
