$(document).ready(function() {
  $('a.coming_soon_dialog').click(function(e){
    $('div.coming_soon_modal').dialog({ height:180,
      title: "Coming Soon",
      modal: true
    });
    return false;
  });
  $(".ui-widget-overlay").on("click", function (){
    $("div:ui-dialog:visible").dialog("close");
  });
});

