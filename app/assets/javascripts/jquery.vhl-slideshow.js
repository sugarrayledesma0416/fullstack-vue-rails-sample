/* Most of this description, and a lot of this plugin are cruft */

/* Explanation of Usage for Default Interface (not groups):

 This plugin is used for the Slideshow with hovers that is found on
 the Student Dashboard in the Suggested Video section, as well as in
 Student Activity Sets and Instructor Grading Sets.

 // Calling the Plugin // It should be called from the Docready with a
 few options passed through it. Example:

 $('#slideshow_container').vhlSlideshow({videoMargin: 30,
 displayedSlides: 3, hoverDiv: '.video_hover', minWidth: 450});

 // Options // videoMargin is the distance that the hover should
 appear from the slideshow item.

 displayedSlides is how many ADDITIONAL slides are visible after
 #1. For instance, in student activity sets this number is 19, because
 we display 20 at once.

 hoverDiv is the class of the div that contains the content for your
 hovers, typically rendered in a separate partial.

 minWidth was added because of something that I had noticed on the
 student dashboard. If you had less than the expected number of
 videos, it would center the layout and the hovers would be
 misaligned. This sets it to essentially always align left by passing
 through a width if the number of slideshow items are less than the
 total displayed.

 // Breakdown of Layout // The breakdown of divs to make this work is
 rather specific, and should be copied and altered from a file such as
 _resources.html.erb, but the basic breakdown is as follows:

<div id="hover_holder" class="ui-helper-clearfix">
</div>
<div id="slideshow_container">
  <div id="slideshow_area">
    <div id="slideshow_scroller">
      <div id="slideshow_holder">
        <% ** FOR EACH ITEM ** %>
        <div class="slideshow_content">
          <div id="** ITEM NUMBER **" class="slideshow_item">
            ** ACTUAL SLIDESHOW CONTENT **
          </div>
          <% ** RENDER PARTIAL CONTAINING HOVER CONTENT. ** %>
        </div>
        <% end %>
      </div>
    </div>
  </div>
</div>
<div id="slideshow_previous">
</div>
<div id="slideshow_next">
</div>

 #hover_holder is where the hover content is appended to. We use a div
 outside of the slideshow for the functionality of it because the
 hover elements need to break free of the "overflow: hidden" that
 makes the slideshow function.

 #slideshow_container is what I've used to call the slideshow from,
  but it also sets the total width of the entire thing.

 #slideshow_area is just inside that and contains the "usable area"
 for slideshow items, leaving room on the sides for the previous/next
 arrows to be placed.

 #slideshow_scroller and #slideshow_holder have their width set by the
 number of slideshow items present. The scroller is what actually
 moves, while the holder keeps the view in place (like things moving
 outside of a window).

 Inside of #slideshow_holder goes the actual .slideshow_content which
 contains each actual slideshow item and its hover (with the item
 wrapped in .slideshow_item and the hover in .slideshow_content and
 whatever was specified by the options. Again, the hovers are
 typically rendered in a separate partial.)

 From there we close out divs, leaving only the the
 #slideshow_previous and #slideshow_next buttons that allow you to
 actually scroll through the items.

 */

(function($) {
  $.fn.extend ({
    vhlSlideshow: function(options) {

      var defaults = {
        videoMargin: 0, // Distance in pixels of the hover content from the Slideshow Item
        displayedSlides: 5, // How many slides are displayed in addition to the first slide
        hoverDiv: '.video_hover', // Div name of the hover content
        minWidth: 450 // Safety for fewer items
      };

      var o = $.extend(defaults, options);

      var slideshow = new o.workset_interface(o);

      return this.each(function(){
        var self = this;

        // Slideshow Functionality
        $("#slideshow_previous").click(function() {
          slideshow.showPreviousSlide();
        });
        $("#slideshow_next").click(function() {
          slideshow.showNextSlide();
        });

        $("#slideshow_scroller").scrollLeft(0);
        slideshow.fixSlideWidth();
        slideshow.updateButtons();

        // Auto-Scroll when in a Workset or Grading Set.
        if (o.hoverDiv === ".workset_activity_hover") {
          var slideshow_containers = $('.slideshow_content').find('li');
          var current_container = slideshow_containers.filter('.current');
          var current_index = slideshow_containers.index(current_container) + 1;

          if (current_index < o.displayedSlides) {
            slideshow.currentSlide = 0;
          } else if (current_index > (slideshow.totalSlides - o.displayedSlides)) {
            slideshow.currentSlide = (slideshow.totalSlides - o.displayedSlides + 1);
          } else {
            slideshow.currentSlide = current_index;
          }

          slideshow.updateContentHolder();
          slideshow.updateButtons();
        }

        // Setting Hover Stuff
        $('.slideshow_item').on('mouseover  focusin', function () {
          slideshow.show_hover(this);
        });
        $('.slideshow_item').on('mouseleave  focusout', function () {
          var video_hover_moved = $('#hover_holder').find(o.hoverDiv + '.on_hover');
          $(video_hover_moved).removeClass('on_hover');
          $(video_hover_moved).addClass('hidden_helper');

          slideshow.replace_video_hover(this, video_hover_moved);

          var video_hover = $(this).find(o.hoverDiv);
          $(video_hover).css('margin-left', 0);
        });
      });
    }
  });
})(jQuery);
