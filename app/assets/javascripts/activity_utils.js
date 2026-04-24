VHL = VHL || {};
VHL.Activity = VHL.Activity || {}

function activityBodyForm() {
  return $('#activity_form');
}

VHL.Activity.Utils = {
  submit_acceptance: function(message) {
    if(confirm(message)) {
      let form = activityBodyForm();
      form.attr('action', (form.attr('action').replace('re_try', 'finalize')));
      return true;
    } else {
      return false;
    }
  },

  retry_activity: function() {
    let form = activityBodyForm();

    // We need to check if the /re_try is in the action before append it
    // because we are seeing issues where the app make POST/GET requests
    // to /:activity_id/re_try/re_try paths.

    if (form.attr('action').indexOf('/re_try') === -1) {
      form.attr('action', (form.attr('action') + '/re_try'));
    }
  },

  save_activity: function() {
    $('.js-activity-save-modal').vhlModal('close');
    if(perform_save_state()) {
      let form = activityBodyForm();

      // We need to check if the /save is in the action before append it
      // because we are seeing issues where the app make POST/GET requests
      // to /:activity_id/save/save paths.

      if (form.attr('action').indexOf('/save') === -1){
        form.attr('action', (form.attr('action') + '/save'));
      }
      return true;
    }else {
      return false;
    }
  },
}
