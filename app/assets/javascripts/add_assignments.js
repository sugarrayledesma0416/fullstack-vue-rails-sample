var VHL = VHL || {};

VHL.AddAssignments = (function() {

  function activityHoverInformation() {

    function _makeActivitiesTableVisible() {
      $(this).siblings('.items_daily').show();
    }

    function _makeActivitiesTableHidden() {
      $(this).siblings('.items_daily').hide();
    }

    var calendar_hover = {
      over: _makeActivitiesTableVisible,
      timeout: 300,
      out: _makeActivitiesTableHidden
    };

    // Don't Throw Errors on the Calendar
    if ($('body').hasClass('assignment_page')) {
      $('[data-day-total-activities="day-total-activities"]').hoverIntent(calendar_hover);
      }
  }


  function prep_common_jquery_modal_local(min_height, width, grab_params) {
    $('a.jquery_modal').unbind('click').bind('click', function() {
      $('#modal_box').dialog({
        title: $(this).attr('title'),
        minHeight: min_height,
        modal: true,
        position: 'top',
        resizable: false,
        width: width,
        open: function (e, ui) {
          $('#modal_box').append("<div id='modal_spinner' style='position:absolute;top:15%;left:40%;'><img alt='page loading' src='/images/loading_32.gif'/></div>");
        },
        close: function() {
          $('#modal_box form').remove();
          $('div.ui-dialog-buttonpane').remove();
        }
      }).load($(this).attr('href'), get_selected_activities(), function() {
          var dlg = $(this);
          $('#modal_spinner').remove();
          $(this).find('form').each(function(){
            $(this).find(':text:first').not('.has_datepicker').focus();
            $btn = $(this).find(':submit');
            $form = $(this);

            var txt = $btn.val();
            $btn.remove();

            var buttons = {};
            buttons[txt] = function() {
              if(typeof confirmation != 'undefined'){
                if (!confirm(confirmation)){
                  dlg.dialog('close');
                  return false;
                }
              }
              $.ajax({
                type: $form.attr('method'),
                url: $form.attr('action'),
                data: $form.serialize(),
                dataType: 'script',
                success: function(xhr, status) {
                  $('#spinner').show();
                  $('input:checkbox[name="selected_activities[]"]:checked').each(function(index) {
                    $(this).removeAttr("checked");
                  });
                  //success = $.parseJSON(data.responseText);
                  //use success data to show flash
                  dlg.dialog('close');
                  window.location.reload();
                },

                error: function(data) {
                  errors = $.parseJSON(data.responseText);
                  if(errors)
                  {
                    VHL.Common.set_error_class_for_fields(errors.fields_with_errors);
                    error_div = $form.find('#jquery_modal_error_status');
                    if(error_div.length == 0) {
                      $form.prepend('<div id="jquery_modal_error_status" class="ui-state-error ui-corner-all">' + errors.errors_message_block + '</div>');
                    } else {
                      error_div.html(errors.errors_message_block);
                    }
                  }
                }
              });
            };

            $(dlg).dialog('option','buttons', buttons );
            VHL.Common.move_jquery_modal_delete_link_into_button_pane();
            VHL.Common.initialize_datepicker();
          });
      });
      return false;
    });
  }

  function get_selected_activities(argument) {
    var selected_actvities = [];
    $('input:checkbox[name="selected_activities[]"]:checked').each(function(index) { selected_actvities.push($(this).val());});

    return  "selected_activities=" + selected_actvities ;
    // body
  }

  function init() {
    prep_common_jquery_modal_local(150);
    activityHoverInformation();

    VHL.Checkboxes.vhl_group_checkboxes({page: 'assignments'});

    $('.set_date_link').disable_link_toggle({
      meth: 'disable',
      disable: 'You must first select an activity.'
    });
  }


  return {
    init: init,
    activityHoverInformation: activityHoverInformation
  };

})();

$(document).ready(function() {
  VHL.AddAssignments.init();
});
