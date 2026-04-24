$(document).ready(function(){
  VHL.SharedActivityReview.init()
})

VHL.SharedActivityReview = (function(){
  function init(){
    $('[data-original-response-selector]').on('click', function(){
        show_original_response($(this).attr('data-original-response-selector'), $(this).attr('data-original-response-label'))
        return false;
    })
  }

  function show_original_response(selector, label) {
    $('.ui-dialog').remove()

    label = (label ? label : "Student's Original Answer")
    $('#'+selector).dialog({
      title: label,
      minWidth: 400,
      modal: false,
      position: 'center',
      resizable: true,
      width: 720,
      closeOnEscape: true,
      open: function(event, ui){
          CKEDITOR.replace(selector,
          {
            startupFocus : false,
            disableObjectResizing : true,
            customConfig : $('#'+selector).attr('data-custom-config'),
            toolbar: [],
            enterMode : CKEDITOR.ENTER_BR,
            readOnly : true,
            toolbarCanCollapse : false,
            removePlugins : 'elementspath',
            resize_enabled : false
          });
        },
      close: function(event, ui){ CKEDITOR.instances[selector].destroy(); }
    });
  }

  return{
    init: init
  }
})()
