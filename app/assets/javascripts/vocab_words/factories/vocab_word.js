var VHL = VHL || {};

VHL.VocabWords.Factories.factory('VocabWord', ['$resource', function ($resource) {
  // vars inside factory should be named different than url params
  var program_id = $('#main_content').attr('data-program-id');

  return $resource('/:program/vocab_words/:id.json',
    { program: program_id, id: '@id' },
    {
      query: {
        method: 'GET',
        isArray: false,
        headers: { 'Cache-Control': 'no-cache, no-store, must-revalidate', 'Pragma': 'no-cache' }
      },
      update: { method: 'PUT'},
      destroy: { method: 'DELETE', params: { default_vocab_word: '@default_vocab_word' } }
    });
}]);
