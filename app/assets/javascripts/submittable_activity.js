// Activity js
//= require activity_utils.js

VHL = VHL || {}

VHL.SubmittableActivity = (function(){

  function init(){
    let inactivityTimeoutEnabled = document.querySelector('.js-vue-timeout-warning[data-enabled-in-selected-school="true"]') !== null;
    var is_practice = ($("#practice").val() ? ($("#practice").val() == 'yes') : false);
    var is_instructor = ($('[name="VHL.is_instructor"]').prop('content') === 'true');
    var is_partner_chat = false;
    var is_assessment_info = document.querySelector('.assessment-unstarted') !== null;

    if ($('body').hasClass('partner_chat') ||
        $('body').hasClass('info_gap_partner_chat') ||
        $('body').hasClass('info_gap_partner_chat_v2')) {
      is_partner_chat = true;
    }

    if (!(is_practice || is_partner_chat || is_instructor) && !inactivityTimeoutEnabled) {
      var timeout = ($("#timeout_override").val() ? $("#timeout_override").val() : 180000);
      $(document).idleTimer(parseInt(timeout));
      $(document).on("idle.idleTimer", function(){
        if (isUserInOnGoingGroupChatCall()) {
          /**
           * Following idleTimer reset is needed for the bug in usecase - when user is idle and
           * call is ended due to action of some other user and further timeout dialog is
           *  not shown because 'idle.idleTimer' events are not triggered.
           * This idleTimer reset call will clear setInterval in the library.
           */
          $(document).idleTimer('reset');
          return;
        }

        // we need to validate is there ANY MMP players around, and then
        // check each state, so, if ANY of them are playing we must avoid this dialog
        // cuz we don't want to show the inactivity warning.
        // this validation will be performed on each timeout

        if(no_media_players_are_playing())
        {
          // cancel help request if open
          $("a#cancel_help").click();

          VHL.RecordTime.remove_time_spent_listener();
          $timeOutDialog = $('#time_out_dialog');
          $timeOutDialog.dialog( {
            open: function() { 
              if(!is_assessment_info){
                update_time_spent($("#start_time").val());
              }
            },
            closeOnEscape: false,
            buttons: [
                       {
                         "text": "Yes",
                         "click": function () { $(this).dialog("close"); },
                         // AllY - For NVDA support.
                         // In case of 'alertdialog' dialog label and description
                         // are not announced by NVDA
                         // Added describedby to default dailog button so that NVDA
                         // announces the dialog text when buton recieved focus
                         'aria-describedby': 'time_out_dialog'
                       },
                       {
                         "text": "No",
                         "click": function () { stop_work(); }
                       }
                    ],
            close: function() { continue_work(); },
            modal: true,
            resizable:false,
            minWidth: 330,
            position: false,
          });
          var $dialogParent = $timeOutDialog.parent();

          $dialogParent.addClass('time_out_dialog');
          $dialogParent.css({'position': 'fixed'});
          // A11Y update - Aria label set as per alert dialog guideline - https://www.w3.org/TR/wai-aria-practices/examples/dialog-modal/alertdialog.html
          $dialogParent.attr("role", "alertdialog");
          $dialogParent.attr("aria-modal", "true");

          $timeOutDialog.siblings('.ui-dialog-buttonpane').find('.ui-button').eq(0).addClass('dialog_keep_working');
        }
      });

      if ($('body').hasClass('activity_popup')) {
        $('a[data-button="return"]').addClass('u-hidden');
      }

    }

    // insert a set of item label hidden fields into the DOM
    set_item_labels();
  };

  /**
   * Returns whether a group chat call is ongoing
   * and the user is either the inviter or the invited in the call.
   * @return {boolean}
   */
  function isUserInOnGoingGroupChatCall(){
    const bodyElm = document.querySelector('body');
    const usersType = [VHL.Chat.GlobalState?.INVITING, VHL.Chat.GlobalState?.INVITED];

    if (bodyElm.classList.contains('group_chat') &&
      usersType.includes(VHL.Chat.GlobalState.callInvitationSide)) {
      return true;
    }
    return false;
  }

  function no_media_players_are_playing(){
    if(typeof jwplayer != 'undefined')
    {
      var all_players = jwplayer.getPlayers();
      for(var index = 0; index < all_players.length; index++) {
        player_status = all_players[index].getState();
        if(player_status == 'PLAYING')
        {
          return false;
        }
      }
    } else if(((typeof swfobject) != 'undefined') && $("#vocab_tutorial_").length != 0) {
      // Do not show dialog when a flash vocab or grammar tutorial is playing.
      return false;
    }
    return true;
  };

  function continue_work() {
    // re-enable visibility listener
    VHL.RecordTime.add_time_spent_listener();
    update_start_time();
    smartbook_resume_time_tracking();
  };

  function stop_work() {
    // update start time so no additional time is recorded as window closes
    update_start_time();

    if($('body').hasClass('activity_popup')) {
      window.close();
    } else {
      window.location = $(".js-activity_return_link").attr('href');
    }
  };

  function smartbook_resume_time_tracking() {
    var activity_type = $('meta[name="VHL.activity_type"]').attr('content');

    if (activity_type === 'smart_book') {
      $.ajax({
        type: 'get',
        url: ($('#activity_time_tracker_url_base').val() + '/smartbook_resume_time_tracking')
      });
    }
  }

  function update_start_time() {
    $("#start_time").val(utc_timestamp());
  };

  function utc_timestamp() {
    // get current utc integer timestamp
    // getTime() returns millisecond resolution
    return Math.floor((new Date()).getTime() / 1000);
  }

  function update_time_spent(start_time) {
    var authTokenName = $('meta[name="csrf-param"]').attr('content');
    var authTokenValue = $('meta[name="csrf-token"]').attr('content');
    var validatedTime = parseInt(start_time, 10);
    var url = $('#activity_time_tracker_url_base').val() + '/update_time_spent';

    // ensure at least 15 seconds has passed so we don't update too frequently.
    // visibility listener seems to trigger more than it should.
    if (utc_timestamp() - validatedTime > 15) {
      if (navigator.sendBeacon && validatedTime > 0) {
        var data = new FormData();
        data.append(authTokenName, authTokenValue);
        data.append('start_time', validatedTime);

        // this is a HTTP POST that isn't affected by page unload
        // https://developer.mozilla.org/en-US/docs/Web/API/Beacon_API/Using_the_Beacon_API
        navigator.sendBeacon(url, data);
      } else {
        // fallback to standard ajax if browser doesn't support sendBeacon()
        $.ajax({
          type: 'post',
          url: url,
          data: `${authTokenName}=${authTokenValue}&start_time=${validatedTime}`,
          async: false
        });
      }
      return true;
    } else {
      // when using visibility change on unsubmittables, this return
      // value should be used to stop update of the form's start_time
      return false;
    }
  }

  function set_item_labels(){
    var container_selector = "div[id=activity_body]";
    var field_selectors = ["input[type=radio]", "input[type=text]", "select", "textarea", "input[type=hidden]"];
    var item_labels = new Set();
    var field_pattern = /question_\d+/;

    for (var i = 0; i < field_selectors.length; i++) {
      var fields = new Array();
      fields = $(container_selector + " " + field_selectors[i]);

      for (var j = 0; j < fields.length; j++) {
        var field_name = fields[j].name;
        if (field_name.match(field_pattern) && !field_name.match('_correction')) {
            item_labels.add(fields[j].name);
        }
      }
    }

    var ctr = 1;
    item_labels.forEach(function(label){
      $('#activity_form').append('<input type="hidden" name="item_labels[]" id="item_labels_' + ctr + '" value="' + label + '"/>');
      ctr++;
    })
  }

  return {
    init: init,
    update_time_spent: update_time_spent,
    update_start_time: update_start_time
  };

}());

//strictness hover namespace

VHL.Strictness = (function() {

    var populate_strictness_hover = function(strictness, info_hover) {
      var hover_arrow = '<div class="hover_tools_arrow"></div>';
      if(strictness.hasClass('active')) {
        var info_text = info_hover.attr('data-js-active');
        info_hover.text(info_text);
      } else {
        var info_text = info_hover.attr('data-js-inactive');
        info_hover.text(info_text);
      }

      // Ensure that the other hovers are closed. Important for IE9.
      var strict_accents = $('[data-js-activity-strictness="accent"]');
      var strict_capitalizations = $('[data-js-activity-strictness="capitalization"]');
      var strict_punctuations = $('[data-js-activity-strictness="punctuation"]');

      if(strictness.hasClass('accent')) {
        strict_capitalizations.addClass('hidden_helper');
        strict_punctuations.addClass('hidden_helper');
      } else if (strictness.hasClass('capitalization')) {
        strict_accents.addClass('hidden_helper');
        strict_punctuations.addClass('hidden_helper');
      } else if (strictness.hasClass('punctuation')) {
        strict_capitalizations.addClass('hidden_helper');
        strict_accents.addClass('hidden_helper');
      }

      info_hover.append(hover_arrow);
      info_hover.toggleClass('hidden_helper');
    };

    var bind_strictness_hovers = function() {
      // accent strictness
      $('li.accents').hover(function(){
        var info_hover = $("[data-js-activity-strictness='accent']");
        VHL.Strictness.populate_strictness_hover($(this), info_hover);
      });
      // capitalization strictness
      $('li.capitalization').hover(function(){
        var info_hover = $("[data-js-activity-strictness='capitalization']")
        VHL.Strictness.populate_strictness_hover($(this), info_hover);
      });
      // punctuation strictness
      $('li.punctuation').hover(function(){
        var info_hover = $("[data-js-activity-strictness='punctuation']")
        VHL.Strictness.populate_strictness_hover($(this), info_hover);
      });
    };

  return {
    populate_strictness_hover: populate_strictness_hover,
    bind_strictness_hovers: bind_strictness_hovers
  }

})();

$(document).ready(function() {
  VHL.SubmittableActivity.init();
  VHL.Strictness.bind_strictness_hovers();
});
