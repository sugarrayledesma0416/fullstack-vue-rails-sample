var VHL = VHL || {};

VHL.VocabWords.Directives.directive('ngvocabcard', function (overflowService, vocabUIHelpers) {
  return {
    link: function (scope, elm, attrs) {
      elm.on('click', function () {
        //remove the hover from card front.
        elm.find('.vocab_card_overflow_hover').remove();

        var card = vocabUIHelpers.getCardAttrs(scope.$eval(attrs.ngCard));
        if (!card.flipped) {
          card.flipped = true;
          //clear out the text from the front of the cards.
          var card_a_text = elm.find('.word .card_a_outer .inner').text("");
          elm.find('.word .card_b_outer .inner').text("");
          //set the card text to the hidden text, css class to appear flipped
          card_a_text.text(card.hidden_text);
          elm.addClass('flipped');
          //rerun overflow hover func in case the flipped card has long text
          overflowService.create_hover(elm.find('.word .card_a_outer'));
          //show the hover since the mouse is in place for expected hover.
          elm.find('.vocab_card_overflow_hover').show();
        }
      });
    }
  };
});
