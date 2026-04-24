$(() => {
  $('.js-new-tab').click(() => {
    this.removeClass('is-current');
    $('.js-viewed-tab').addClass('is-current');
  });
  $('.js-viewed-tab').click(() => {
    this.removeClass('is-current');
    $('.js-new-tab').addClass('is-current');
  });
});
