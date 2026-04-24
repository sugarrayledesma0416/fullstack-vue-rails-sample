var VHL = VHL || {};

(function() {

  const KEY_CODES = {
    ENTER: 13,
    SPACE: 32,
    T_KEY: 84,
  };

  function two_minutes_or_less(time) {
    return time <= 1000 * 60 * 2;
  }

  VHL.AssessmentTimer = (function () {
    var constructor = function() {
      this.is_open = false;
    }

    function to_milliseconds(s) {
      return (s * 1000);
    }

    function zero_pad(n) {
      var nstr = n.toString();
      return (nstr.length === 1) ? ('0' + nstr) : nstr;
    }

    constructor.prototype = {
      init_timer_display: function() {
        const $assessment_timer = $('#assessment_timer');
        if ($assessment_timer.length && !$assessment_timer.hasClass('minimized')) {
          this.is_open = true;
        }
        const timer_display = $('.timer-display');

        $assessment_timer.click((event)=> {
          $(timer_display).toggle();
          $(event.currentTarget).toggleClass('minimized');
          this.is_open = !this.is_open;
        });

        $assessment_timer.on('keydown', (event) => {
          const key = event.keyCode;
          if (key === KEY_CODES.ENTER || key === KEY_CODES.SPACE) {
            $(timer_display).toggle();
            $assessment_timer.toggleClass('minimized');
            this.is_open = !this.is_open;
          }
        });

        $(document).on('keydown', (event) => {
          const key = event.keyCode;
          if (event.altKey && key === KEY_CODES.T_KEY) {
            const time_left_ms = to_milliseconds(this.time_left_seconds);
            if (!this.is_open) {
              $(timer_display).show();
              $assessment_timer.removeClass('minimized');
              this.is_open = true;
            }
            this.a11y_announce_time(time_left_ms, true);
          }
        });
      },
      two_minute_warning: function(time_remaining) {
        if (!two_minutes_or_less(time_remaining)) {
          return;
        }

        /**
         * if it is 2 minutes (or less),
         * remind the user to save work,
         * and open the timer if it is not already open.
         */
        VHL.Assessments.showSaveWorkWarning();

        if (!this.is_open) {
          $('.timer-display').show();
          $('#assessment_timer').removeClass('minimized');
          this.is_open = true;
          this.a11y_announce_time(time_remaining, true);
        }
      },
      a11y_announce_time: function(time_remaining, force) {
         if(force || this.announceAlertPercent.indexOf(time_remaining) > -1) {
          var timeLeftHr = this.timer_display_hr[0].textContent;
          var timeLeftMin = this.timer_display_min[0].textContent;
          var timeLeftSec = this.timer_display_sec[0].textContent;
          $('.js-a11y-time-remaining').text(`Time Remaining ${timeLeftHr}:${timeLeftMin}:${timeLeftSec}`);
         }
      },

      start: function (args) {
        var self = this;
        this.polling_interval = args.polling_interval;
        this.time_left_seconds = this.time_limit_seconds = args.time_left_seconds;
        this.timer_display_hr = args.timer_elm.find('.hr');
        this.timer_display_min = args.timer_elm.find('.min');
        this.timer_display_sec = args.timer_elm.find('.sec');
        this.sync_url = args.sync_url;
        this.original_time_seconds =  args.original_time_seconds;

        // a11y Announce time when 50% and 25% of total time remaining
        this.announceAlertPercent = [50, 25];
        this.announceAlertPercent = this.announceAlertPercent.map(function(value) {
            var roundedTime =  Math.round((value * self.original_time_seconds) / 100);
            return to_milliseconds(roundedTime);
        })

        this.assessment_timeout = setTimeout(this.submit_assessment.bind(this), to_milliseconds(this.time_limit_seconds));
        this.display_interval = setInterval(this.display_updater.bind(this), to_milliseconds(1));
        this.poll_interval = setInterval(this.sync_server.bind(this), to_milliseconds(this.polling_interval));
        this.radial_timer = args.radial_timer;
      },
      display_updater: function () {
        if (this.time_left_seconds > 0) {
          this.time_left_seconds--;
          var time_left_ms = to_milliseconds(this.time_left_seconds);
          $(this.timer_display_hr).html(zero_pad(Math.floor(this.time_left_seconds / 3600)));
          $(this.timer_display_min).html(zero_pad(Math.floor((this.time_left_seconds % 3600) / 60)));
          $(this.timer_display_sec).html(zero_pad(this.time_left_seconds % 60));
          this.radial_timer.animate(time_left_ms);
          this.radial_timer.timer_style(time_left_ms);
          this.two_minute_warning(time_left_ms);
          this.a11y_announce_time(time_left_ms);
        }
      },
      sync_server: function() {
        var self = this;
        // dont poll in the last 2 intervals so that some race conditions can be avoided.
        if (self.time_left_seconds > (self.polling_interval * 2)) {
          $.ajax({
            type: "PUT",
            url: self.sync_url,
            dataType: 'json',
            success: function (response) {

              time_left_seconds_on_server = (response.time_left > 0) ? response.time_left : 0;

              if (time_left_seconds_on_server != self.time_left_seconds) {
                self.time_left_seconds = time_left_seconds_on_server;
                clearTimeout(self.assessment_timeout);
                self.assessment_timeout = setTimeout(self.submit_assessment.bind(self), to_milliseconds(self.time_left_seconds));
              }
            }
          });
        }
      },
      submit_assessment: function () {
        //clear protect work flag
        is_storing_work();
        //hide the activity form
        $('#activity_form').hide();
        //hide ok button, till the ajax is complete
        $('#auto_submit').show();

        clearInterval(this.display_interval);
        clearInterval(this.poll_interval);
        var form = $('#activity_form');
        var form_url = form.attr('action');

        /**
         * If there are ckeditor instances in the form,
         * update them so that the contents will be included
         * if the form is submitted via AJAX.
         */
        if (typeof(CKEDITOR) !== 'undefined') {
          for (instance in CKEDITOR.instances) {
            CKEDITOR.instances[instance].updateElement();
          }
        }

        $.ajax({
          type: "POST",
          url: form_url,
          data: form.serialize(),
          dataType: 'json',
          async: false,
          success: function () {
            $('#auto_submit .status').html('Your work has been submitted successfully.');
          },
          error: function () {
            $('#auto_submit .status').html('There has been an error in submitting your work, please contact your instructor.');
          }
        });
      }
    };
    return constructor;
  })();

  VHL.RadialTimer = (function() {

    var constructor = function(original_time_limit) {
      this.original_time_limit = original_time_limit;
    };

    var colors = {
      blue: '#98C5E4',
      gray: '#E6E7E8',
      red: '#CC6A77'
    };

    function make_gradient(arc_1, color_1, arc_2, color_2) {
      var hex_1 = colors[color_1] || colors['blue'];
      var hex_2 = colors[color_2] || colors['blue'];
      var first_arc = 'linear-gradient(' + arc_1 + 'deg, '+ hex_1 + ' 50%, transparent 50%, transparent),';
      var second_arc = ' linear-gradient(' + arc_2 + 'deg, #E6E7E8 50%, ' + hex_2 + ' 50%, ' + hex_2 + ')';
      return first_arc + second_arc;
    }

    constructor.prototype = {
      animate: function(time_remaining) {
        /* animate the background-image gradient property */

        var percent = time_remaining / this.original_time_limit;

        /* return degrees that have been completed for percent of time left*/
        var arc = 1 - 360 * percent;

        /* There are different arc offsets and different color settings for the first
         and second half of the duration. We start with an arc value based off the percentage of time remaining.
         That will be a value between 0 - 360 degrees. Using that number, we generate the appropriate offset.  */

        if (!two_minutes_or_less(time_remaining)) {
          this.generate_arc(arc, 'blue');
        } else {
          this.generate_arc(arc, 'red');
        }
      },
      generate_arc: function(arc, color) {
        if (arc < -180) {
          // in the first half of the timer circle
          $('.timer-animation').css('background-image', make_gradient(90, color, arc + 90, color));
        } else {
          // in the second half of the timer circle
          $('.timer-animation').css('background-image', make_gradient(arc - 270, 'gray', 270, color));
        }
      },
      timer_style: function(time_remaining) {
        /* changes display of counter when there is less than an hour remaining */
        if(time_remaining < 60 * 60 * 1000) {
          var countdown = $('.countdown');
          countdown.find('.hr, .hr-divider').hide();
          countdown.addClass('large-clock');
          /* if time left is between 2:00 and 1:55, show red numbers */
          if(time_remaining < 60 * 2 * 1000) {
            countdown.addClass('ending-countdown-color');
          }
        }
      }
    }

    return constructor;
  })();

  $(document).ready(function () {
    var radial_timer = new VHL.RadialTimer(parseInt($('#original_time_limit').val(), 10) * 1000);
    var assessment_timer = new VHL.AssessmentTimer();
    assessment_timer.start({
      polling_interval: parseInt($('#poll_interval').val(), 10),
      time_left_seconds: parseInt($('#assessment_time_left').val(), 10),
      original_time_seconds: parseInt($('#original_time_limit').val(), 10),
      sync_url: '/attempt/' + $('#attempt_id').val() + '/sync_time',
      timer_elm: $('#assessment_timer'),
      radial_timer: radial_timer
    });
    assessment_timer.init_timer_display();
  });

})();
