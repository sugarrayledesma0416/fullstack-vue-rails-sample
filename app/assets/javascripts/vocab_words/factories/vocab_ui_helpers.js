var VHL = VHL || {};

VHL.VocabWords.Factories.factory('vocabUIHelpers', function () {
  var vocabUIHelpers = {};
  vocabUIHelpers.getCardAttrs = function (card) {
    var card = card;
    return card;
  }

  vocabUIHelpers.cleanViewValue = function(view_value) {
    var view_value = view_value.replace(/(<([^>]+)>)/ig,"");
    return view_value;
  }

  return vocabUIHelpers;
});
