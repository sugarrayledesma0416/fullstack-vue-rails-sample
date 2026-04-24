var VHL = VHL || {}

VHL.RecordTime = (function() {
  function init() {
    $('form').each(function() {
      $(this).data('initialForm', $(this).serialize());
    }).submit(function() {
      // remove event listener to avoid doubling time_spent on submit
      remove_time_spent_listener();
    });
  }

  function record_time_spent() {
    return VHL.SubmittableActivity.update_time_spent($("#start_time").val());
  }

  function reset_start_time() {
    VHL.SubmittableActivity.update_start_time();
  }

  function check_visibility_state() {
    // if page is hidden for any reason, record time spent and
    // reset the start time on the page so we'll include time
    // spent away, emulating the on-going methodology.
    if (document.visibilityState === 'hidden') {
      if (VHL.RecordTime.record_time_spent()) {
        // update form start_time only if time spent was recorded.
        VHL.RecordTime.reset_start_time();
      }
    }
  }

  function add_time_spent_listener() {
    var submittable = $('meta[name="VHL.activity_submittable"]').attr('content');

    if (submittable === 'true') {
      document.addEventListener('beforeunload', VHL.RecordTime.record_time_spent)
    } else {
      document.addEventListener('visibilitychange', VHL.RecordTime.check_visibility_state);
    }
  }

  function remove_time_spent_listener() {
    var submittable = $('meta[name="VHL.activity_submittable"]').attr('content');

    if (submittable === 'true') {
      document.removeEventListener('beforeunload', VHL.RecordTime.record_time_spent)
    } else {
      document.removeEventListener('visibilitychange', VHL.RecordTime.check_visibility_state);
    }
  }


  return {
    init: init,
    add_time_spent_listener: add_time_spent_listener,
    record_time_spent: record_time_spent,
    remove_time_spent_listener: remove_time_spent_listener,
    reset_start_time: reset_start_time,
    check_visibility_state: check_visibility_state
  }

})();

$(document).ready(function() {
  VHL.RecordTime.init();
  VHL.RecordTime.add_time_spent_listener();
});
