window.onload = function() {
  let reportModal = document.querySelector('.js-modal-report');
  let reportButton = document.querySelector('.js-button-report');
  reportButton && reportButton.addEventListener('click', () => {
    $(reportModal).vhlModal('open');
  });
}


