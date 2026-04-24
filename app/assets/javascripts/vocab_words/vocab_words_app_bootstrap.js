//= require maestro_activity_engine/vhl_ng/bootstrap
//= require_self
//= require_tree ../vocab_words
var VHL = VHL || {};

VHL.VocabWords = angular.module('vocab_words_app', ['vhl.common', 'vocab_words_app.controllers']);

VHL.VocabWords.Controllers = angular.module('vocab_words_app.controllers', ['ngResource', 'vocab_words_app.directives', 'vocab_words_app.factories', 'vocab_words_app.filters']);
VHL.VocabWords.Directives = angular.module('vocab_words_app.directives', []);
VHL.VocabWords.Factories = angular.module('vocab_words_app.factories', []);
VHL.VocabWords.Filters = angular.module('vocab_words_app.filters', []);
