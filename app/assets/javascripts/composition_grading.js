//= require activity_review

VHL.CompositionGrading = (function() {
  // Toggle the student response in grading and review modes
  function toggle_student_response() {

    $('[data-js-composition=original_response]').each(function(){
      var view_original_link = $(this);
      var response_container = view_original_link.parent().siblings('#composition_original_answer').find('[data-js-composition="response_container"]');

      view_original_link.on('click', function(){
        if (response_container.hasClass('hidden_helper')) {
          response_container.removeClass('hidden_helper');
          view_original_link.text('Hide original response');
        } else {
          response_container.addClass('hidden_helper');
          view_original_link.text('View original response');
        }
        return false;
      });
    });
  }

  return {
    toggle_student_response: toggle_student_response
  }

})();

$(document).ready(function() {
  VHL.CompositionGrading.toggle_student_response();
});
