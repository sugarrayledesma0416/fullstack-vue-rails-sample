var VHL = VHL || {};

VHL.DefaultWorkset = (function() {
  /* amount in px the slideshow
   * will shift each arrow click
   */
  var SHIFT = 90;

  function DefaultWorkset(options) {
    this.scroller = $('#slideshow_scroller');
    this.holder = $('#slideshow_holder');
    this.area = $('#slideshow_area');
    this.options = options;
  };

  DefaultWorkset.prototype.updateButtons = function() {
    $("#slideshow_next").toggle(this.toggleNextBtn());
    $("#slideshow_previous").toggle(this.togglePrevBtn());
  };

  DefaultWorkset.prototype.get_workset_width = function(workset) {
    return this.holder.width();
  };

  /* the container for the slides must be slightly bigger than
   the total width of the slides themselves. */
  DefaultWorkset.prototype.set_container_width = function(workset_width) {
    /* we want the container to be 1px larger than its contents */
    return workset_width + 1;
  };


  DefaultWorkset.prototype.fixSlideWidth = function() {},

  DefaultWorkset.prototype.updateContentHolder = function() {};

  DefaultWorkset.prototype.showNextSlide = function() {
    var scrollPos = this.scroller[0].scrollLeft;
    this.scroller[0].scrollLeft = scrollPos + SHIFT;
    this.updateButtons();
  };

  DefaultWorkset.prototype.showPreviousSlide = function() {
    var scrollPos = this.scroller[0].scrollLeft;
    this.scroller[0].scrollLeft = scrollPos - SHIFT;
    this.updateButtons();
  };

   DefaultWorkset.prototype.show_hover = function(element) {
   var placement = $(element).position().left;
   var activity_id = $(element).data('worksetItem');
   var video_hover = this.set_video_hover(activity_id, element);
   $(video_hover).removeClass('hidden_helper');
   $(video_hover).addClass('on_hover');
   $('#hover_holder').append(video_hover);
   var video_hover_moved = $('#hover_holder').find(this.options.hoverDiv + '.on_hover');
   $(video_hover_moved).css('margin-left', placement - this.options.videoMargin);
  };

  DefaultWorkset.prototype.set_video_hover = function(activity_id, item) {
    return $(item).siblings(this.options.hoverDiv);
  };

  DefaultWorkset.prototype.replace_video_hover = function(item, video_hover_moved) {
    $(item).parent().append(video_hover_moved);
  };

  DefaultWorkset.prototype.toggleNextBtn = function() {
    var areaWidth = parseInt(this.area.width());
    var holderWidth = parseInt(this.holder.width());
    var scrollDistance = parseInt(this.scroller.scrollLeft());
    return (areaWidth + scrollDistance) < holderWidth;
  };

  DefaultWorkset.prototype.togglePrevBtn = function() {
    return parseInt(this.scroller.scrollLeft()) > 0;
  };

  return DefaultWorkset;
})();
