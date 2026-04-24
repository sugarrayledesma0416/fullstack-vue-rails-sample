$(document).ready(() => {
  $('#igc_copy_confirm').hide();
  $('.c-flash-banner__close-link').addClass('js-x-minimize');

  // If user has closed the copy content dialog, show the minimized version
  if(sessionStorage.getItem('copyDialogMinimized')) {
    $('#igc_copy').addClass('u-hidden');
    $('#igc_copy_minimized').removeClass('u-hidden');
  }

  $('.js-copy-content-modal').click(() => {
    $('.js-confirm-copy').vhlModal('open');
  });

  $('.js-copy-content-run').click((event) => {
    let url = `${location.pathname}/generated_content_copy/run`;
    $.ajax({
      type: 'post',
      url: url,
      data: {
        src_program_id: $(event.target).data('source-program-id')
      }
    })
    .then(() => {
      /**
       * The controller adds a message to the flash on either success
       *   or error. The flash is displayed on reload.
       */
      location.reload(true);
    });
  });

  $('.js-x-minimize').click((event) => {
    $('#igc_copy').addClass('u-hidden');
    $('#igc_copy_minimized').removeClass('u-hidden');
    sessionStorage.setItem('copyDialogMinimized', 'true');
  });
});
