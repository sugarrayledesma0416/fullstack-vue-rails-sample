import DeepLinkModal from './deep_link_modal.js';

window.addEventListener('DOMContentLoaded', (event) => {
  let modalElm = document.querySelector('.js-create-deep-link-modal');
  let links = document.querySelectorAll('.js-deep-link-activity-control');
  const modal = new DeepLinkModal(modalElm, links);
});
