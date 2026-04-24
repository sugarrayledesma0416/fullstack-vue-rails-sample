var VHL = VHL || {};

VHL.VocabWords.Factories.factory('overflowService', function() {
  var overflowService = {};
  overflowService.create_hover = function(element) {
    function trim_entry (str) {
      str = str.replace(/^\s+/, '');
      for (var i = str.length - 1; i >= 0; i--) {
        if (/\S/.test(str.charAt(i))) {
          str = str.substring(0, i + 1);
          break;
        }
      }
      return str;
    }
    //find the text, figure out if it is too long for card.
    var inner_text = $(element).find('.inner').text();
    inner_text = trim_entry(inner_text);
    var text_length = inner_text.length;
    var cutoff_limit = 100;

    //if text is too long, truncate what is shown on card.
    if(text_length > cutoff_limit) {
      var show_on_card = inner_text.slice(0, cutoff_limit);
      show_on_card = show_on_card + "...";
      var show_in_hover = inner_text.slice(cutoff_limit, text_length);
      $(element).find('.inner').text(show_on_card);

        //defer the overflow text to a hover
      var hover = angular.element('<div class="vocab_card_overflow_hover"><div class="overflowed_text"></div><div class="vocab_hover_arrow"></div></div>');
      hover.hide();
      hover.find('.overflowed_text').text(show_in_hover);
      element.after(hover);

      //bind the hover to a mouseover event
      element.hover(
        function() {
          hover.show();
        },
        function() {
          hover.hide();
        }
      );
    }
  }
  return overflowService;
})

