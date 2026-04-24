/* Explanation of Usage:

This plugin is to be used for any circumstances for which we have a link that the user should not be able to 
click on until they perform some other action. Examples would be things such as the Instructor TOC: They should
not be able to "Assign selected" activities before they have chosen any to assign. Another example is the 
ARC activities. A user should not be able to click "Review" to play back their recording if they have not yet 
created one. This plugin is included gobally through the site since it is rather small and has a wide range
of pages that require it. 

Here is an example of the code used to disable a link.

  $('#student_info_22').disable_link_toggle({
    meth: 'disable', 
    disable: 'You cannot edit a closed course.'
  });

The first selector is the element that you wish to grab. This can be a class, an id, or even a data-js 
element. Once you have that, you call the vhlDisableLink function, which has a total of three possible 
options.
  
- Meth stands for Method. This is where you tell the function whether you are disabling or enabling the 
link. This is the only option that is absolutely required.

- Disable is only used if you are disabling the link. This is where you enter the text for why the link
is disabled. When the user mouses over the disabled link, this will be shown to them in a hover as an
explanation.

There is also a hover inclusion in Application.js that deals with what to do when you aren't using this 
plugin but want to maintain the same sort of style. For example, on the Instructor Dashboard when one
is focused on a closed course, the link is conditionally replaced with a span in the code itself. 

In a case such as this, we use the following:

  <span class="disable_link_function">Edit Course
    <span class="disabled_hover_info hidden_helper">You cannot edit a closed course.</span>                        
  </span>
  
Where the related classes are styled in layout.css and the javascript to show/hide the 
disabled_hover_info is stored within application.js, which is also called globally.

*/

(function($) {
  $.fn.extend ({
    /* The first function we have in this plugin is called map_attributes. What this does is 
    return the attributes of the given element. These are things like Class, Href, ID. It
    will also grab inline javascript like onclick. This function is run as .map_attributes()
    and actually returns these as an array, similar to how .data() works for data- properties.
    This function uses both .map_attributes and .data to ensure that we're passing all of the 
    relevant information over to the span that we create. */
    
    map_attributes: function(prefix) {
    	var maps = [];
    	$(this).each(function() {
    		var map = {};
    				
    		for(var i=0; i<this.attributes.length; i++) {
    			if(!prefix || this.attributes.item(i).name.substr(0,prefix.length) == prefix) {
    				map[this.attributes.item(i).name] = this.attributes.item(i).value;
    			}
    		}
    		maps.push(map);
    	});
    	return (maps.length > 1 ? maps : maps[0]);
    },

    // This is the actual function for disabling and enabling links.
    disable_link_toggle: function(options) {
        
      var defaults = {
        meth: 'disable',                  // Method. Are we disabling or enabling the link?
        disable: 'This link is disabled'  // Disable Only. This is the text that should be displayed in the hover, explaining why the link is disabled. 
      };

      var options = $.extend(defaults, options);
      var o = options;
      
      $(this).each(function() {
        var wtd = $(this).outerWidth() + 10;  // Width of the Text. We'll use this to position the hover. 
        
        if (wtd < 80) {
          wtd = 80;
        }
        
        var dis = o.disable;                  // The Disable Text.
        var txt = $(this).html();             // The Link Text.
        
        // If we're disabling the link, run this.
        if (o.meth == 'disable') {  
            // Generate New Span
            var text_to_insert = [];
            var j = 0;
        
            // Attributes
            var attributes = $(this).map_attributes();

            for (var attribute in attributes) {  
              // Don't pass the onclick or href.
              if (attribute == 'href') {
              }
              else if (attribute == 'onclick') {
              }
              // The title is replaced by the hover.
              else if (attribute == 'title') {
              }
              // The class is handled elsewhere.
              else if (attribute == 'class') {
              }
         
              // Everything else
              else {                                  
                text_to_insert[j++] = attribute + "=\"" + attributes[attribute] + "\"";
              }
              
              // And here's how we do the class.
              var has_class = false;
              
              if ('class' in attributes) {
                has_class = true;
              } else {
                has_class = false;
              }
              
              if (has_class == true) {
                text_to_insert[j++] = "class=\"" + attributes['class'] + " disable_link_function" + "\"";
              } else {
                text_to_insert[j++] = "class='disable_link_function'";
              }
            }

            // Put it all together. 
            var stored = text_to_insert.join(' ');
            
            // Only do the replacement if it has not already been done
            if ($(this).hasClass('hidden_helper') || $(this).hasClass('disable_link_function')) {

            } else {
              // Have a disabled hover if we pass one in.              
              if (o.disable == "") {
                $(this).parent().append('<span ' + stored + '>' + txt + '</span>');
                $(this).addClass("hidden_helper");
              } else {
                var hoverinfo = '<span class="disabled_hover_info hidden_helper">' + dis + '</span>';
                // Replace the Link with a Span
                $(this).parent().append('<span ' + stored + '>' + txt + hoverinfo + '</span>');
                $(this).addClass("hidden_helper");
                // Position the Hover
                $('.disabled_hover_info').css('left', wtd);
              }
            }
          }

          // If we're not disabling, we must be enabling. 
          else if (o.meth == 'enable') {
            // Remove the span and uncover the link.
            $(this).removeClass('hidden_helper');
            $(this).siblings('.disable_link_function').remove();
        }
      });
      
      VHL.Common.disable_link_hover();
    }
  })
})(jQuery);