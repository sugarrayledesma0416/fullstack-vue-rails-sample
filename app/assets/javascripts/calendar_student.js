var VHL = VHL || {};

/**
 * Class to handle month change for student calendar.
 */
VHL.EventCalendarStudent = class {

  /**
   * Do initial setup eg. css class updates & set up event handler
   */
  constructor() {
    this.updateCalendarClasses();
    this.bindMonthChange();
  }

  /**
   * Update css classes for some calendar elements.
   */
  updateCalendarClasses() {
    $('.js-calendar-week:first').addClass('c-first-week');
    $('.js-day--today').siblings('.js-day').addClass('c-this-week');
    $('.js-day--class-day').each((index, element) => {
      let $headerIndex = $(element).index();
      let $headerElement = $('.js-calendar-weekday').eq($headerIndex);
      $headerElement.addClass('c-calendar-weekday--class_day');
    });
  }

  /**
   * Set up event handler to change month in calendar.
   */
  bindMonthChange() {
    // event is bound on parent element of element ('.js-month-change') 
    //   to avoid rebinding due to dynamic html load.
    $('.js-calendar-container').on('click', '.js-month-change', (event) => {
      event.preventDefault();
      let yearMonth = $(event.currentTarget).attr('data-js-month');
      this.changeCalendar(yearMonth);
    });
  }

   /**
   * get new calendar html based on year_month parameter
   *
   * @param  {String} yearMonth New month of calendar to display.
   */
  changeCalendar(yearMonth) {
    if (yearMonth.length > 0) {
      let containerEle = $('.js-calendar-container');
      let ajaxUrl = VHL.Common.build_ajax_url('/event_calendar/' + yearMonth);

      $.ajax({
        type: "get",
        url: ajaxUrl,
        beforeSend: (xhr, status) => {
          // show spinner indicating change in process
          $('.js-calendar-spinner').show();
        },
        success: (responseHtml) => {
          containerEle.html(responseHtml);
          this.updateCalendarClasses();
        },
        complete: () => {
          $('.js-calendar-spinner').hide();
        },
      });
    }
  }
}

$(document).ready(() => {
  new VHL.EventCalendarStudent();
});
