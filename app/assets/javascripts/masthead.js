var VHL = VHL || {}

VHL.Masthead = (function() {

  function init() {
    bind_body_close();
    bind_ipad_close();
    bindLogoutLink();
  }

  function bindLogoutLink() {
    $('.js-logout-link').click(function () {
      sessionStorage.removeItem('show_assigned_activities');
      sessionStorage.removeItem('show_content');
      return true;
    });
  }

  function bind_body_close() {
    // Clicking links within the menus will not close them.
    $('.current_user_name').on("click touchend", function(event) {
      event.stopPropagation();
    });

    $('.current_user_menu_item a').on("click touchend", function(event) {
      event.stopPropagation();
    });

    $('.help_menu_link').on("click touchend", function(event) {
      event.stopPropagation();
    });

    $('.help_menu_item a').on("click touchend", function(event) {
      event.stopPropagation();
    });

    $('#chat_drop_control, #live_chat_menu').on("click touchend", function(event) {
      event.stopPropagation();
    });
  }

  function bind_ipad_close() {
    // Clicking the page with an iPad will close tooltips.
    $('body').bind('touchstart', function(event) {
     event = event.originalEvent;
     var tgt = event.touches[0] && event.touches[0].target,
         $tgt = $(tgt);

     if (tgt.nodeName !== 'A' && !$tgt.closest('div.cluetip').length) {
       $(document).trigger('hideCluetip');
     }
    });
  }




  return {
    init: init
  };
})();

$(document).ready(function() {
  VHL.Masthead.init();
});
