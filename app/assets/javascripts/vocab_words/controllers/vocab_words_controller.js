var VHL = VHL || {};

VHL.VocabWords.Controllers.controller('VocabCtrl', ['$scope', '$document', '$filter', '$http', '$timeout', 'VocabWord', function ($scope, $document, $filter, $http, $timeout, VocabWord) {

  /**
   * Since we cannot stream a PDF back to the user via AJAX, we need to build a temporary form and submit it to initiate the PDF download.
   * @param {string} study_sheet_type: the type of pdf the student wants to print. This is passed in from the view.
   */
  $scope.print_pdf = function (study_sheet_type) {
    var program_id = $('#main_content').data('program-id');
    var params = _.inject(_.flatten($scope.paged_items),
      function (m, v) {
        if (parseInt(v.default_vocab_word) === 1) {
          m['default_vocab_word_ids'].push(v.id);
        } else {
          m['vocab_word_ids'].push(v.id);
        }
        return m;
      }, { vocab_word_ids: [], default_vocab_word_ids: [] });

    var form = '<form action="/' + program_id + '/vocab_words/print_pdf" id="print_pdf" method="post">';
    _.each(params.vocab_word_ids, function (word, index) {
      form += '<input name="vocab_word_ids[]" value="' + word + '" type="hidden" />';
    });
    _.each(params.default_vocab_word_ids, function (word, index) {
      form += '<input name="default_vocab_word_ids[]" value="' + word + '" type="hidden" />';
    });
    form += '<input name="study_sheet_type" value="' + study_sheet_type + '" type="hidden" />';
    form += '<input name="authenticity_token" value="' + $("meta[name='csrf-token']").attr("content") + '" type="hidden" />';
    form += '</form>';
    $('body').append(form);
    $('#print_pdf').submit();
    $('#print_pdf').remove();
  };

  // pagination variables init
  $scope.items_per_page = 30;
  // $scope.paged_items = [];
  $scope.current_page = 0;

  // Init the add word submit to be disabled
  $scope.add_word_disabled = true;

  // Init word added success message flag
  $scope.add_word_success_enabled = false;

  // selected_lesson from dropdown
  $scope.selected_lesson = null;

  // selected_lesson to filter and search words
  $scope.searcher_selected_lesson = null;

  // programs the user has access to
  $scope.programs_size = null;

  $scope.sort_reverse = false;

  $scope.recorder = {};

  $scope.current_word = {};

  function recording_params() {
    var recording_path = $scope.current_word.recording_path;
    var params = {new_recording: !recording_path};
    if (recording_path) {
      params.recording_path = recording_path;
    }
    return params;
  }

  $scope.initialize_recorder = function () {
    $scope.recorder.initialize(recording_params());
  };

  $scope.initialize_viewer = function (vocab_word) {
    $scope.current_word = vocab_word;
  };

  $scope.search_by_lesson = function () {
    var selected_lesson = $scope.searcher_selected_lesson;
    if (selected_lesson) {
      $scope.search_results = _.filter($scope.search_results, function (word) {
        return word.lesson_id === selected_lesson.id;
      });
    }
  };

  function search_by_term_and_lesson() {
    $scope.search_results = $scope.vocab_words;
    if (!_.isEmpty($scope.search_term)) {
      // filter words by specified term in search_term input field if is not empty
      $scope.search_results = $filter('search_filter')($scope.search_results, $scope.search_term);
    }
    $scope.search_by_lesson();
  }

  $scope.handle_paste = function () {
    // since we're using ng-model to set search_term
    // we need to add a short delay to wait for it to be set
    $timeout(function() {
      search_by_term_and_lesson();
      $scope.paginate_words($scope.search_results);
    }, 100);
  }

  $scope.$watch("searcher_selected_lesson", function (new_val) {
    search_by_term_and_lesson();
    if (new_val) {
      $scope.paginate_words($scope.search_results);
    }
  });

  $scope.search_and_paginate_results = function () {
    // Passes the current search results so to optimize the algorithm to not search through the entire vocab list as the user refines the input
    // On backspace the search-input directive resets the search results to equal the entire set of vocab words
    $scope.search_results = $filter('search_filter')($scope.search_results, $scope.search_term);
    $scope.paginate_words($scope.search_results);
  };

  //Initialize sorting
  $scope.current_sort = {
    target_word: false,
    target_definition: false,
    base_word: false,
    created_at: false,
    lesson_name : true
  };

  //turn our predicate into user friendly stuff. will need refactor if we add new languages.
  var build_sort_name_mapping = function () {
    var sort_name_mapping = {
      created_at: 'Date Added',
      target_word: $scope.program_language,
      target_definition: 'Definition',
      base_word: 'English',
      lesson_name: 'Lesson'
    };
    return sort_name_mapping;
  };

  // sets an infinite(imposible) index value to place null lessons at the bottom of the sorter list
  function lesson_index(lesson) {
    var index = (lesson !== null) ? lesson.split(' ')[1] : '10000000Z';
    return index;
  }

  function lesson_rank(lesson) {
    var index = lesson_index(lesson);
    var rank = parseInt(index);
    return rank;
  }

  function integer_sort(word) {
    return lesson_rank(word.lesson_name);
  }

  function alpha_sort(word) {
    var index = lesson_index(word.lesson_name);
    var numeric_rank = lesson_rank(word.lesson_name);
    var alpha = index.replace(numeric_rank, '');
    var alpha_rank = alpha.charCodeAt();
    return alpha_rank;
  }

  function toggle_sort_direction() {
    if ($scope.predicate === 'created_at') {
      $scope.sort_reverse = true;
    } else {
      $scope.sort_reverse = !$scope.sort_reverse;
    }
  }

  function do_sort() {
    search_by_term_and_lesson();

    var sort_criteria = ($scope.predicate === 'lesson_name') ? [integer_sort, alpha_sort] : [$scope.predicate, 'id'];
    $scope.search_results = $filter('orderBy')($scope.search_results, sort_criteria, $scope.sort_reverse);
    $scope.paginate_words($scope.search_results);
  }

  //initialize sort name to Date Added
  $scope.set_sort_predicate = function (predicate) {
    if (predicate === 'created_at' || $scope.current_sort[predicate]) {
      toggle_sort_direction();  // reverse sort direction only when predicate is unchanged
    }

    $scope.predicate = predicate;
    $scope.ui_sort_name = $scope.sort_name_mapping[predicate];

    _.each($scope.current_sort, function (val, key) {
      $scope.current_sort[key] = false;
    });
    // current_sort is indicating the filter we're going to apply
    // so, we need to set the predicate position to true in order to filter by the specified field
    $scope.current_sort[$scope.predicate] = true;

    do_sort();
  };

  $scope.paginate_words = function (words) {
    $scope.paged_items = [];
    var i;
    for (i = 0; i < words.length; i = i + 1) {
      if (i % $scope.items_per_page === 0) {
        $scope.paged_items[Math.floor(i / $scope.items_per_page)] = [ words[i] ];
      } else {
        $scope.paged_items[Math.floor(i / $scope.items_per_page)].push(words[i]);
      }
    }

    $scope.current_page = 0;
  };

  var set_program_language = function (vocab_json) {
    var language_codes = {
      es: 'Spanish',
      fr: 'French',
      de: 'German',
      it: 'Italian',
      zh: 'Chinese',
      ru: 'Russian',
    };

    return language_codes[vocab_json.language];
  };

  //Practice Mode Stuff
  var build_practice_modes = function () {
    var practice_modes = [
      {
        name: 'Given English provide the ' + $scope.program_language,
        css_class: 'target_base',
        shown_header: 'English Word',
        hidden_header: $scope.program_language + ' Word',
        practice_set_limit: 20,
        build_card: function (vocab_word) {
          if (!_.isEmpty(vocab_word.base_word) && !_.isEmpty(vocab_word.target_word)) {
            return {
              flipped: false,
              shown_text_a: vocab_word.base_word,
              shown_text_b: '',
              hidden_text: vocab_word.target_word
            };
          }
        }
      },
      {
        name: "Given Definition provide the "  + $scope.program_language,
        css_class: 'def_target',
        shown_header: 'Definition',
        hidden_header: $scope.program_language + ' Word',
        practice_set_limit: 9,
        build_card: function (vocab_word) {
          if (!_.isEmpty(vocab_word.target_word) && !_.isEmpty(vocab_word.target_definition)) {
            return {
              flipped: false,
              shown_text_a: vocab_word.target_definition,
              shown_text_b: '',
              hidden_text: vocab_word.target_word
            };
          }
        }
      },
      {
        name: "Given "  + $scope.program_language + " provide the English",
        css_class: 'target_base',
        shown_header: $scope.program_language + ' Word',
        hidden_header: 'English Word',
        practice_set_limit: 20,
        build_card: function (vocab_word) {
          if (!_.isEmpty(vocab_word.target_word) && !_.isEmpty(vocab_word.base_word)) {
            return {
              flipped: false,
              shown_text_a: vocab_word.target_word,
              shown_text_b: '',
              hidden_text: vocab_word.base_word
            };
          }
        }
      },
      {
        name: "Given " + $scope.program_language + " provide the Definition",
        css_class: 'target_def',
        shown_header: $scope.program_language + " Word",
        hidden_header: 'Definition',
        practice_set_limit: 9,
        build_card: function (vocab_word) {
          if (!_.isEmpty(vocab_word.target_word) && !_.isEmpty(vocab_word.target_definition)) {
            return {
              flipped: false,
              shown_text_a: vocab_word.target_word,
              shown_text_b: '',
              hidden_text: vocab_word.target_definition
            };
          }
        }
      },
      {
        name: "Given Definition and English provide the " + $scope.program_language,
        css_class: 'def_base_target',
        shown_header: 'Definition and English',
        hidden_header: $scope.program_language + ' Word',
        practice_set_limit: 9,
        build_card: function (vocab_word) {
          if (!_.isEmpty(vocab_word.target_word) &&
              !_.isEmpty(vocab_word.base_word) &&
              !_.isEmpty(vocab_word.target_definition)) {
            return {
              flipped: false,
              shown_text_a: vocab_word.base_word,
              shown_text_b: vocab_word.target_definition,
              hidden_text: vocab_word.target_word
            };
          }
        }
      }
    ];
    return practice_modes;
  };

  $scope.has_multiple_programs = function () {
    programs = $scope.programs_size || $scope.programs_counter();
    return programs != 1;
  };

  $scope.programs_counter = function () {
    program_names = _.uniq(_.pluck($scope.lessons, 'program_name'));
    return $scope.programs_size = _.size(program_names);
  }

  $scope.filtered_lessons = function (lessons) {
    // use lesson.name if lesson.label is undefined
    _.each(lessons, function (lesson) {
      lesson.name = (lesson.label != '') ? lesson.label : lesson.name;
    });
    $scope.lessons = lessons;
  }

  // Fetch all words from server.
  // Init data structures that need program language
  $scope.vocab_data = VocabWord.query({}, function (response) {
    $scope.vocab_words = response.activities;
    $scope.filtered_lessons(response.lessons);
    $scope.paginate_words($scope.vocab_words);

    // Init the search results to equal the entire set of vocab words
    $scope.search_results = $scope.vocab_words;

    // init data structures that need program language
    $scope.program_language = set_program_language(response);
    $scope.practice_modes = build_practice_modes();
    $scope.sort_name_mapping = build_sort_name_mapping();

    // set default sort
    $scope.ui_sort_name = $scope.sort_name_mapping['lesson_name'];

    $scope.$broadcast('hide_spinner');
  }, function (response) {
    $scope.show_an_error();
    $scope.$broadcast('show_spinner');
  });

  // Init the current_word to have empty strings, so to avoid problems with null values if the user doesn't input data in all the fields
  $scope.new_vocab_word = {
    target_word: "",
    target_definition: "",
    base_word: ""
  };

  $scope.set_current_word = function (vocab_word) {
    $scope.current_word = vocab_word;
    $scope.$apply();

    /* Make sure that the textareas within the editable word are correctly
    initialized so that we can get the proper 'caret' location on them for
    the purpose of adding accented characters. */
    VHL.AccentBar.init();

  }

  $scope.get_current_word = function (vocab_word) {
    return $scope.current_word === vocab_word;
  }

  $scope.$on('select_word', function(event, vocab_word) {
    $scope.set_current_word(vocab_word);
    //Not ready yet to go live
    //$scope.initialize_recorder();
  });

  $scope.$on('clear_selected_word', function() {
    $scope.set_current_word('');
  });

  $scope.$on('save_word', function() {
    $scope.update_vocab_word($scope.current_word)
  });

  function assign_lesson_id() {
    $scope.new_vocab_word.lesson_id = $scope.selected_lesson && $scope.selected_lesson.id;
  }

  $scope.clear_new_word = function() {
    $scope.new_vocab_word.target_word = '';
    $scope.new_vocab_word.target_definition = '';
    $scope.new_vocab_word.base_word = '';
    $scope.add_word_disabled = true;
    $scope.set_current_word('');
  }

  $scope.add_vocab_word = function() {
    assign_lesson_id();

    var vocab_word = VocabWord.save(
      {
        // vocab_word: _.extend($scope.new_vocab_word, {recording_path: $scope.recorder.recording_path()})
        vocab_word: $scope.new_vocab_word
      },
      function (response) {
        response.lesson_name = $scope.selected_lesson && $scope.selected_lesson.name;

        $scope.add_word_success_enabled = true;
        $scope.vocab_words.push(vocab_word);
        $scope.set_sort_predicate('created_at');
      },
      function (response) { $scope.build_error_dialog(response.data.errors); }
    );

    $scope.new_vocab_word = {
      target_word: "",
      target_definition: "",
      base_word: "",
      lesson_id: null
    };
    $scope.selected_lesson = null;
    $scope.add_word_disabled = true;
  };

  $scope.add_vocab_tag = function (new_vocab_tag) {
   //helper functions only used inside of add_vocab_tag
    function is_new_tag(value) {
      return !_.contains(_.pluck($scope.current_word.vocab_tags, 'name'), value);
    }

    if (!$.isEmptyObject(new_vocab_tag) && new_vocab_tag.name !== "") {
      new_vocab_tag.name = new_vocab_tag.name.trim();
      if (is_new_tag(new_vocab_tag.name)) {
        if (!$scope.current_word.vocab_tags_attributes) {
          $scope.current_word.vocab_tags_attributes = [];
        }
        if (!$scope.current_word.vocab_tags) {
          $scope.current_word.vocab_tags = [];
        }
        $scope.current_word.vocab_tags.push(new_vocab_tag);
        $scope.current_word.vocab_tags_attributes.push(new_vocab_tag);
      } else {
        alert('Tag name already exists.');
      }
      new_vocab_tag = {};
    }

    String.prototype.trim = function () {
      return this.replace(/^\s+|\s+$/g, "");
    };
  };

  $scope.remove_vocab_tag = function (tag_name) {
    if (tag_name) {
      var item = _.find($scope.current_word.vocab_tags, function (tag) {
        return tag.name === tag_name;
      });
      if (item && item['default_vocab_word_id']) {
        //When doing a copy on edit, the vocab_tags_attributes is populated with all the tags and their names.
        //if we are deleting a default tag, meaning we are about to do a copy on edit, find the
        //prepopulated tag in vocab_tags_attributes, and set it to have _destroy = 1. Then in $scope.save_vocab_tag_changes,
        //that tag with _destroy = 1 will get filtered out of the request params, since there is no id yet.
        item = _.find($scope.current_word.vocab_tags_attributes, function (tag) {
          return tag.name === tag_name;
        }) || item;
        item['_destroy'] = 1;
      } else {
        item['_destroy'] = 1;
        $scope.current_word.vocab_tags_attributes = _.reject($scope.current_word.vocab_tags_attributes, function (tag) {
          return tag.name === item.name;
        });
        $scope.current_word.vocab_tags_attributes.push(item);
        $scope.current_word.vocab_tags = _.without($scope.current_word.vocab_tags, item);
      }
    } else {
      var popped_item = $scope.current_word.vocab_tags.pop();
      if (popped_item && popped_item['default_vocab_word_id']) {
        popped_item = _.find($scope.current_word.vocab_tags_attributes, function (tag) { return tag.name === popped_item.name; }) || popped_item;
        popped_item['_destroy'] = 1;
      } else {
        popped_item['_destroy'] = 1;
        $scope.current_word.vocab_tags_attributes = _.reject($scope.current_word.vocab_tags_attributes, function (tag) {
          return tag.name === popped_item.name;
        });
        $scope.current_word.vocab_tags_attributes.push(popped_item);
      }
    }
  };

  $scope.save_vocab_tag_changes = function () {
    //remove any tags marked as {name: 'tag', '_destroy': 1} because those are not actually in db
    $scope.current_word.vocab_tags_attributes = _.reject($scope.current_word.vocab_tags_attributes, function (param) {
      return _.isUndefined(param.id) && param['_destroy'];
    });
    if (!_.isEmpty($scope.current_word.vocab_tags_attributes)) {
      var vocab_word = $scope.current_word;

      VocabWord.update({ vocab_word: _.pick($scope.current_word, 'language', 'target_word', 'base_word', 'target_definition', 'default_vocab_word', 'vocab_tags_attributes'), id: vocab_word.id }, function (response) {
          vocab_word.vocab_tags_attributes = [];
          vocab_word.default_vocab_word = 0;
          _.each(response, function (val, key) {
            vocab_word[key] = val;
          }); //copy new attrs to old word
      }, function (response) {
        $scope.build_error_dialog(response.data.errors);
      });
    }
  };

  $scope.save_uploaded_image = function(vocab_word) {
    $scope.update_vocab_word(vocab_word);
    $scope.$broadcast('image_saved');
  };

  $scope.save_recording = function () {
    $scope.current_word.recording_path = $scope.recorder.recording_path();
    $scope.update_vocab_word($scope.current_word);
    $scope.$broadcast('recording_saved');
  };

  $scope.delete_recording = function () {
    if (window.confirm('Are you sure you want to delete your recording?')) {
      $scope.current_word.recording_path = '';
      $scope.update_vocab_word($scope.current_word);
      $scope.$broadcast('stop_recorder'); // Shows record button again
    }
  };

  $scope.find_lesson = function (lesson_id) {
    return _.where($scope.lessons, {id: lesson_id})[0];
  }

  $scope.update_vocab_word = function (vocab_word) {
    //content editable inserts <br> and <p> tags when the element is left blank. we need to remove these.
    vocab_word.target_word = $scope.remove_tags_and_whitespace(vocab_word.target_word);
    vocab_word.target_definition = $scope.remove_tags_and_whitespace(vocab_word.target_definition);
    vocab_word.base_word = $scope.remove_tags_and_whitespace(vocab_word.base_word);

    //update the record
    //dont post the vocab_tags key when updating only a vocab word

    VocabWord.update({ vocab_word: _.omit(vocab_word, 'vocab_tags', 'vocab_tags_attributes', 'recording_id', 'image_filename', 'public_filename'), id: vocab_word.id }, function (response) {
        // Replace old object with the new one returned from the server.
        // This appropriately handles the copy-on-edit that occurs when
        // editing a default word.
      var index = _.indexOf($scope.vocab_words, vocab_word);
      _.each(response, function (val, key) { $scope.vocab_words[index][key] = val; }); //copy new attrs to old word
      $scope.vocab_words[index].default_vocab_word = undefined;
      $scope.$broadcast('stop_recorder');
    }, function (response) {
      $scope.build_error_dialog(response.data.errors);
    });
  };

  $scope.destroy_image = function(vocab_word) {
    vocab_word._destroy_image = '1';
    $scope.update_vocab_word(vocab_word);
    $scope.$broadcast('image_saved');
  };

  $scope.delete_vocab_word = function (vocab_word) {
    VocabWord.destroy(vocab_word, function (response) {
      $scope.search_results = $scope.vocab_words = _.reject($scope.vocab_words, function (word) {
        return word === vocab_word;
      });
      $scope.search_and_paginate_results();
    }, function (response) { $scope.build_error_dialog(response.data.errors); });
  };

  $scope.remove_tags_and_whitespace = function (entry) {
    entry = entry.replace(/(<([^>]+)>|&nbsp;)/ig, "");
    return entry.replace(/^\s+|\s+$/g, '');
  };

  $scope.build_error_dialog = function (error_text) {
    var error_dialog = $("<div class='vocab_error'></div>").text(error_text);
    error_dialog.dialog({modal: true,
      title: "error",
      buttons: [ {text: "ok", click: function () {
        $(this).dialog("close");
      }}]});
  };

  $scope.prev_page = function () {
    if ($scope.current_page > 0) {
      $scope.current_page--;
    }
  };

  $scope.next_page = function () {
    if ($scope.current_page < $scope.paged_items.length - 1) {
      $scope.current_page++;
    }
  };

  $scope.set_page = function (page) {
    if ($scope.current_page !== page) {
      $scope.current_page = page;
      window.scrollTo(0, 0);
    }
  };

  /**
   Kick off a vocab practice session.
   @param {object} mode - $scope.practice_modes (from ng-repeat 'mode in practice_modes')
   */

  $scope.start_practice = function (mode) {
    $scope.practice_mode = mode;
    $scope.shuffle_cards();
    $scope.deal_cards($scope.practice_mode.practice_set_limit);
  };

  $scope.practice_more = function (practice_set_limit) {
    if ($scope.shuffled_cards.length < practice_set_limit) {
      $scope.shuffle_cards();
    }
    $scope.deal_cards(practice_set_limit);
  };

  $scope.deal_cards = function (practice_set_limit) {
    $scope.practice_cards = $scope.shuffled_cards.splice(0, practice_set_limit);
  };

  $scope.build_practice_cards = function () {
    return _.compact(_.map($scope.search_results, function (word) {
      return $scope.practice_mode.build_card(word);
    }));
  };

  $scope.shuffle_cards = function () {
    $scope.shuffled_cards = _.shuffle($scope.build_practice_cards());
  };

}]);
