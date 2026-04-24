VHL = VHL || {}

VHL.Announcement = class Announcement {
  
  constructor() {
    VHL.Common.initialize_datepicker();
    this._attachEventHandlers();
    this._calendarInputHandler();
  }
  
  /**
   * @summary Attach event handlers to Jquery elements
   */
  _attachEventHandlers() {
    $('.js-calendar-input').on('change', () => this._calendarInputHandler());
  }

  /**
   * @summary Handles event when change are made to calendar Input field 
   */
  _calendarInputHandler() {
    let $datePicker = $('.js-calendar-input');
    let $calendarErrorLabel = $('.js-calendar-error-label');
    let announcementDate = $datePicker.val();
    let isDateFormatted = this._isDateFormatted(announcementDate);

    // Display error  when date entered is not empty and in upsupported format
    if (announcementDate !== '' && isDateFormatted) {
      $datePicker.removeClass('u-bord-1  u-bord-error');
      $calendarErrorLabel.addClass('u-dis-none');
      this._enableCancelClass();
    } else if(announcementDate !== '' && !isDateFormatted){
      $datePicker.addClass('u-bord-1  u-bord-error');
      $calendarErrorLabel.removeClass('u-dis-none');
      this._disableCancelClass();
    }else {
      this._disableCancelClass();
    }
  }

  /**
   * @summary Enables cancel class checkbox 
   */
  _enableCancelClass() {
    $('.js-cancel-class').prop('disabled', false);
  }

  /**
   * @summary Disables cancel class checkbox 
   */
  _disableCancelClass() {
    $('.js-cancel-class').prop('disabled', true);
    $('.js-cancel-class').prop('checked', false);
    $('.js-calendar-input').val('');
  }

  /**
   * @summary Checks if date passed is in supported format
   * @params {String} date | String containing date
   * @returns {boolean} 'true' When format is supported, 'false' When format is unsupported
   */
  _isDateFormatted(date) {
    if ($.datepicker.parseDate('mm/dd/yy', date) == null &&
      $.datepicker.parseDate('yy-mm-dd', date) == null) {
      return false;
    }
    return true;
  }
}

$(document).ready(function () {
  new VHL.Announcement();
});
