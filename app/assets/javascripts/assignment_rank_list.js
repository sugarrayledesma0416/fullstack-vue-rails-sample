var VHL = VHL || {};

VHL.AssignmentRankList = (function () {
  function init() {
    $("#assignment_rank_list").sortable({
      cancel: ".regular"
    });
    $("#assignment_rank_list").disableSelection();
  };

  function set_strand_name () {
    var strand_name = $('#current_strand_name').text();
    $("#rank_list_strand_name").text(strand_name);
  }

  return {
    init: init,
    set_strand_name: set_strand_name
  };

}());

$(document).ready(function () {
  VHL.AssignmentRankList.init();
  VHL.AssignmentRankList.set_strand_name();
});
