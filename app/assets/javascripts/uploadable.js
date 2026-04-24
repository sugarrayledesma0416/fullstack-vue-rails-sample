/* global VHL */

VHL.uploadable = (function() {
  var file_container_switch = function(status) {
    var link = $('[data-container=replace_file_link] a');
    switch (status) {
    case 'show':
      link.html('Keep current file');
      link.unbind('click');
      link.bind('click', function() {
        file_container_switch('hide');
        return false;
      });
      link.attr('onclick', "file_container_switch('hide'); return false;");
      $('[data-container=file_field]').css('display', 'block');
      $('[data-container=file_field] input#file_uploading').attr('value', 'needed');
      break;
    case 'hide':
      link.html('Replace current file');
      link.unbind('click');
      link.bind('click', function() {
        file_container_switch('show');
        return false;
      });
      $('[data-container=file_field]').css("display", "none");
      $('[data-container=file_field] input#file_uploading').attr('value', 'dismissed');
      break;
    }
  };

  return {
    file_container_switch : file_container_switch
  };
})();

$(document).ready(function() {
  // The code for Announcements and Resources is slightly different
  // and should eventually be rewritten for consistency.

  // Announcements
  if ($('#has_file').val() === 'has_file') {
    VHL.uploadable.file_container_switch('hide');
  }

  // Resources
  if ($('body').hasClass('js-resources')) {
    var unitLabel = 'last_' + $('#valid_unit_label').val();
    VHL.Resources.validate_unit(unitLabel);
    VHL.Resources.toggleMultiLessonSelects();
  }
});
