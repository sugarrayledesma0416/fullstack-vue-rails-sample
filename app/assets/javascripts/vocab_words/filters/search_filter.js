var VHL = VHL || {};

VHL.VocabWords.Filters.filter('search_filter', function () {
  //helper function for filter
  function any_item_in_list_contains_string(list, str) {
    return _.any(list, function (item) { return item.indexOf(str) !== -1; });
  }

  //helper function for filter
  function all_search_terms_found_in_list(search_terms, list) {
    return _.all(search_terms, function (term) { return any_item_in_list_contains_string(list, term); });
  }

  //another helper function
  function downcase_and_remove_accents(arr) {
    return _.map(arr, function (el) { return VHL.Common.remove_diacritics(el.toLowerCase()); });
  }

  return function (vocab_words, query) {
    if (_.isEmpty(query)) { return vocab_words; }

    var search_terms = query.split(' ');
    var arrayToReturn = [];
    var i, word, tags, word_attrs_and_tags, searchable_attrs;
    for (i = 0; i < vocab_words.length; i++) {
      word = vocab_words[i];
      tags = _.pluck(word.vocab_tags, 'name');
      searchable_attrs = _.chain(word).pick('target_word', 'base_word', 'target_definition').values().compact().value();
      word_attrs_and_tags = searchable_attrs.concat(tags);
      word_attrs_and_tags = downcase_and_remove_accents(word_attrs_and_tags);
      search_terms = downcase_and_remove_accents(search_terms);
      if (all_search_terms_found_in_list(search_terms, word_attrs_and_tags)) {
        arrayToReturn.push(word);
      }
    }
    return arrayToReturn;
  };
});
