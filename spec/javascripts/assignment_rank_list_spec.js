//= require assignment_rank_list

describe('VHL.AssignmentRankList', function () {
  beforeEach(function () {
    setFixtures('<div id="current_strand_name">Foo Bar</div><ul id="assignment_rank_list"><li class="regular"></li><li class="instructor-created"></li></ul><div id="rank_list_strand_name"></div>');
    spyOn($.fn, 'sortable').andCallThrough();
    spyOn($.fn, 'disableSelection');
  });

  describe('#init', function () {
    it('initializes sortable on the specified element and disables elements that have "regular" css class', function () {
      VHL.AssignmentRankList.init();
      expect($.fn.sortable).toHaveBeenCalledWith({cancel : '.regular'});
      expect($.fn.disableSelection).toHaveBeenCalled();
    });
  });

  describe('#set_strand_name', function () {
    it('sets strand name to the specified selector', function () {
      VHL.AssignmentRankList.set_strand_name();
      var expected_text = $("#rank_list_strand_name").text();
      expect(expected_text).toEqual('Foo Bar');
    });
  });

});
