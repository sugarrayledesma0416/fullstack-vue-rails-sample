//= require angular-resource
//= require fine_uploader/fine_uploader_directive
//= require  maestro_activity_engine/accent_bar/accent_bar
//= require vocab_words/vocab_words_app_bootstrap
//= require vocab_words/controllers/vocab_words_controller
//= require maestro_activity_engine/vhl_ng/bootstrap

describe('VHL.VocabWords', function () {
  describe('VocabCtrl', function () {
    beforeEach(module('vocab_words_app'));
    var $httpBackend, $document, $filter, mock_data, new_word, $scope, $controller, $timeout, VocabWord;
    var url = '/48/vocab_words.json';

    beforeEach(function () {
      this.addMatchers({
        toEqualData: function (expected) {
          return angular.equals(this.actual, expected);
        }
      });

      setFixtures('<div id="main_content" data-program-id="48"></div>');
    });

    function apply_and_flush() {
      $scope.$apply();
      $httpBackend.flush();
    }

    beforeEach(inject(function ($injector) {
      mock_data = {
        language: 'es',
        activities: [{"target_word" : "gato", "target_definition" : "small meowing animal", "base_word" : "cat"},
                     {"target_word" : "perro", "target_definition" : "small barking animal", "base_word" : "dog"}]
      };

      $scope = $injector.get('$rootScope');
      $filter = $injector.get('$filter');
      $controller = $injector.get('$controller');
      $document = $injector.get('$document');
      VocabWord = $injector.get('VocabWord');
      $httpBackend = $injector.get('$httpBackend');
      $timeout = $injector.get('$timeout');
      $httpBackend.when('GET', url).respond(mock_data);

      $controller('VocabCtrl', { $document: $document, $filter: $filter, $scope: $scope, $timeout: $timeout, VocabWord: VocabWord });
      spyOn($scope, '$broadcast').andCallThrough();
    }));

    afterEach(function () {
      $httpBackend.verifyNoOutstandingExpectation();
      $httpBackend.verifyNoOutstandingRequest();
    });

    describe('on initialization', function () {
      var paginate_spy;

      beforeEach(function () {
        paginate_spy = spyOn($scope, 'paginate_words');
        apply_and_flush();
      });

      it("should fetch vocab words from server", function () {
        expect($scope.vocab_words.length).toEqual(2);
      });

      it('sets the words per page to 30', function () {
        expect($scope.items_per_page).toEqual(30);
      });

      it('shows only the first 100 words', function () {
        expect(paginate_spy).toHaveBeenCalled();
      });

      it('puts the user on the first page', function () {
        expect($scope.current_page).toEqual(0);
      });
    });

    describe("#print_pdf", function () {
      var append_spy, submit_spy, remove_spy, expected_form;
      beforeEach(function () {
        apply_and_flush();
        // words with default_vocab_word = 0 are non default vocab words
        $scope.paged_items = [ [{id: 1, name: 'word_on_page_1', default_vocab_word: '0'}],
                               [{id: 2, name: 'word_on_page_2', default_vocab_word: 0}],
                               [{id: 3, name: 'default_word_on_page_3', default_vocab_word: '1'}],
                               [{id: 4, name: 'default_word_on_page_4', default_vocab_word: 1}] ];
        append_spy = spyOn($.fn, 'append');
        submit_spy = spyOn($.fn, 'submit');
        remove_spy = spyOn($.fn, 'remove');

        expected_form = '<form action="/48/vocab_words/print_pdf" id="print_pdf" method="post">';
        expected_form += '<input name="vocab_word_ids[]" value="1" type="hidden" />';
        expected_form += '<input name="vocab_word_ids[]" value="2" type="hidden" />';
        expected_form += '<input name="default_vocab_word_ids[]" value="3" type="hidden" />';
        expected_form += '<input name="default_vocab_word_ids[]" value="4" type="hidden" />';
        expected_form += '<input name="study_sheet_type" value="spanish_english" type="hidden" />';
        expected_form += '<input name="authenticity_token" value="' + $("meta[name='csrf-token']").attr("content")
                      + '" type="hidden" /></form>';
        $scope.print_pdf('spanish_english');
      });

      it('appends a form onto the body that contains vocab word ids and default vocab word ids', function () {
        expect(append_spy).toHaveBeenCalledWith(expected_form);
      });

      it('submits the appended form', function () {
        expect(submit_spy).toHaveBeenCalled();
      });

      it('removed the appended form after submit', function () {
        expect(remove_spy).toHaveBeenCalled();
      });
    });

    describe('#initialize_recorder', function () {
      var recording_params;

      beforeEach(function () {
        apply_and_flush();
        var recorder_mock = jasmine.createSpyObj('recorder', ['initialize']);
        recording_params = {new_recording: true};
        $scope.recorder = recorder_mock;
      });

      describe('when recording does not exist', function () {
        it('initializes a recorder indicating the recorder is new', function () {
          $scope.initialize_recorder();
          expect($scope.recorder.initialize).toHaveBeenCalledWith(recording_params);
        });
      });

      describe('when recording exists', function () {
        it('initializes a recorder indicating the recorder path', function () {
          $scope.current_word.recording_path = '/a/path';
          $scope.initialize_recorder();

          expect($scope.recorder.initialize).toHaveBeenCalledWith({new_recording: false, recording_path: '/a/path'});
        });
      });
    });

    describe('#handle_paste', function () {
      var words;

      beforeEach(function () {
        words = [
          {id: 1, base_word: 'aa', target_definition: 'aa' },
          {id: 2, base_word: 'bb', target_definition: 'bb' },
          {id: 3, base_word: 'cc', target_definition: 'cc' }
        ];
        $scope.vocab_words = words;
        $scope.search_term = 'bb';
      });

      it('filter words at copy-paste text', function () {
        var paginate_spy = spyOn($scope, 'paginate_words');
        $scope.handle_paste();

        $timeout.flush();
        expect(paginate_spy).toHaveBeenCalledWith([ words[1] ]);
        apply_and_flush();
      });
    });

    describe("#search_and_paginate_results", function () {
      it('searches/filters the vocab_words and repaginates based on those results', function () {
        apply_and_flush();
        var paginate_spy = spyOn($scope, 'paginate_words');

        var words = [{ target_word: 'filled', base_word: 'filled_base', target_definition: '' }];
        $scope.search_results = words;
        $scope.search_term = "fill";

        $scope.search_and_paginate_results();
        expect(paginate_spy).toHaveBeenCalledWith(words);
      });
    });

    describe("table sorting", function () {
      beforeEach(function () {
        apply_and_flush();
      });

      it("sets the initial sort parameters", function () {
        expect($scope.ui_sort_name).toBe('Lesson');
        expect($scope.current_sort).toEqualData({ target_word: false, target_definition: false, base_word: false, created_at: false, lesson_name: true });
      });

      describe("#set_sort_predicate", function () {
        it("sets the predicate", function () {
          $scope.set_sort_predicate('target_word');
          expect($scope.predicate).toBe('target_word');
        });

        it("sets the sort_name", function () {
          $scope.set_sort_predicate('target_word');
          expect($scope.ui_sort_name).toBe('Spanish');
        });

        it('resets the pagination ', function () {
          var pagination_spy = spyOn($scope, 'paginate_words');
          $scope.set_sort_predicate('lolcat');
          expect(pagination_spy).toHaveBeenCalled();
        });

        describe("when sorting by Date Added", function () {
          it('always sorts in reverse order', function () {
            $scope.sort_reverse = false;
            $scope.set_sort_predicate('created_at');
            expect($scope.sort_reverse).toEqual(true);
          });
        });

        describe('when not sorting by Date Added', function () {
          it('preserves the reverse order flag state when predicate changes', function () {
            $scope.sort_reverse = true;
            $scope.set_sort_predicate('target_definition');
            expect($scope.sort_reverse).toEqual(true);
          });

          it('toggles the reverse order flag state when predicate remains the same', function () {
            $scope.sort_reverse = true;
            $scope.set_sort_predicate('target_definition');
            $scope.set_sort_predicate('target_definition');
            expect($scope.sort_reverse).toEqual(false);
          });
        });

        describe('when filter by lesson_name', function () {
          it('sort by lesson numbers first and characters after', function () {
            var pagination_spy = spyOn($scope, 'paginate_words');
            $scope.vocab_words = [
              { lesson_name: "Leçon 10A" },
              { lesson_name: "Leçon 10B" },
              { lesson_name: null },
              { lesson_name: "Leçon 1A" },
              { lesson_name: "Leçon 1B" }
            ];

            var expected_filtered_words = [
              $scope.vocab_words[2],
              $scope.vocab_words[1],
              $scope.vocab_words[0],
              $scope.vocab_words[4],
              $scope.vocab_words[3]
            ];

            $scope.sort_reverse = false;
            $scope.set_sort_predicate('lesson_name');
            expect(pagination_spy).toHaveBeenCalledWith(expected_filtered_words);
          });
        });

        describe('when filter by lesson and after by target_definition', function () {
          it('does not reset lesson filters', function () {
            $scope.searcher_selected_lesson = { id: 3 };
            $scope.sort_reverse = false;

            var pagination_spy = spyOn($scope, 'paginate_words');
            $scope.vocab_words = [
              { lesson_name: "Leçon 10B", lesson_id: 2 },
              { lesson_name: "Leçon 1A", lesson_id: 3 },
            ];

            var expected_filtered_words = [ $scope.vocab_words[1] ];

            $scope.set_sort_predicate('target_definition');
            expect(pagination_spy).toHaveBeenCalledWith(expected_filtered_words);

          });
        });

      });
    });

    describe("#paginate_words", function () {
      it('groups words according to items per page and sets paged items', function () {
        apply_and_flush();
        $scope.items_per_page = 5;
        $scope.paginate_words([1, 2, 3, 4, 5, 6]);

        expect($scope.paged_items).toEqual([ [1, 2, 3, 4, 5], [6] ]);
      });
    });

    describe("#clear_new_word", function() {
      beforeEach(function () {
        apply_and_flush();
        new_word = { target_word : "one", target_definition : "two", base_word : "three", lesson_name: null };
        $scope.current_word = new_word;
        $scope.new_vocab_word = new_word;
        $scope.add_word_disabled = false;
      });

      it("clears the fields for the new word", function() {
        $scope.clear_new_word();
        expect($scope.new_vocab_word.target_word).toEqual('');
        expect($scope.new_vocab_word.target_definition).toEqual('');
        expect($scope.new_vocab_word.base_word).toEqual('');
      });

      it("resets the current_word", function() {
        $scope.clear_new_word();
        expect($scope.current_word).toEqual('');
      });

      it("disables the save button for the new word", function() {
        $scope.clear_new_word();
        expect($scope.add_word_disabled).toBeTruthy();
      });
    });

    describe("accented bar search and filtering", function () {
      beforeEach(function () {
        apply_and_flush();
        $scope.vocab_words = [{id: 1, base_word: 'é', lesson_id: 1, vocab_tags: [] },
                              {id: 2, base_word: 'yyy', lesson_id: 2, vocab_tags: [] },
                              {id: 3, base_word: 'zzz', lesson_id: 1, vocab_tags: [] } ];
        $scope.search_results = $scope.vocab_words;
      });

      it('returns filtered words with accented characters', function () {
        $scope.search_term = "é";
        var paginate_spy = spyOn($scope, 'paginate_words');
        $scope.search_and_paginate_results();
        expect($scope.search_results).toEqual([ $scope.vocab_words[0] ]);
      });

      it('returns accented words filtered by lesson', function () {
        $scope.searcher_selected_lesson = {"id": 1};
        $scope.$digest();
        $scope.search_results;

        $scope.search_term = "é";
        var paginate_spy = spyOn($scope, 'paginate_words');

        $scope.search_and_paginate_results();
        expect($scope.search_results).toEqual([ $scope.vocab_words[0] ]);
      });
    });

    describe("#add_vocab_word", function () {
      beforeEach(function () {
        var lesson_id = 1;
        new_word = { target_word : "one", target_definition : "two", base_word : "three", lesson_name: null };
        apply_and_flush();
        $scope.recorder.recording_path = function () { return '/my/path'; };
        $scope.selected_lesson = { id: lesson_id };
      });

      describe('when post is successful', function () {
        beforeEach(function () {
          $scope.current_word = new_word;
          $httpBackend.expect('POST', url).respond(201, new_word);
          $scope.add_vocab_word();
          apply_and_flush(); //POST vocab_words
        });

        it("saves the new vocab word on the server", function () {
          expect($scope.vocab_words[2]).toEqualData(new_word);
        });

        it('sets the sort to sort words by created at, so most recently created shows up at top', function () {
          expect($scope.predicate).toEqual('created_at');
          expect($scope.sort_reverse).toEqual(true);
        });

        it('sets the add word sucess message flag to true', function () {
          expect($scope.add_word_success_enabled).toEqual(true);
        });

        it("clears new_vocab_word", function () {
          var expected_word = { target_word : '', target_definition : '', base_word : '', lesson_id: null };
          expect($scope.new_vocab_word).toEqual(expected_word);
        });
      });

      describe("when an error occurs", function () {
        it('shows a dialog with the error messages', function () {
          $httpBackend.when('POST').respond(500, { errors: 'error response' });
          var error_spy = spyOn($scope, 'build_error_dialog');
          $scope.add_vocab_word();
          apply_and_flush(); //POST vocab_words
          expect(error_spy).toHaveBeenCalledWith('error response');
        });
      });
    });

    describe("#add_vocab_tag", function () {
      var new_vocab_tag;

      beforeEach(function () {
        $scope.current_word = { id: 1, vocab_tags: [], vocab_tags_attributes: [] };
        new_vocab_tag = { name : "test_name" };
        apply_and_flush(); //clear out pending GET requests, as they are not needed here
      });

      describe("when the new vocab tag name is not blank", function () {
        beforeEach(function () {
          $scope.add_vocab_tag(new_vocab_tag);
        });

        it("saves the new vocab tag for the specified vocab word", function () {
          expect($scope.current_word.vocab_tags[0].name).toEqual('test_name');
        });

        it("adds the new tag to the vocab_word's vocab_tags_attributes", function () {
          expect($scope.current_word.vocab_tags_attributes).toEqualData([{name: 'test_name'}]);
        });
      });

      describe("when someone tries to add a tag that already exists", function () {
        it('shows an alert message', function () {
          $scope.current_word = { id: 1, vocab_tags: [{name: 'test_name'}] };
          var alert_spy = spyOn(window, 'alert');
          $scope.add_vocab_tag(new_vocab_tag);
          expect(alert_spy).toHaveBeenCalledWith('Tag name already exists.');
        });
      });
    });


    describe("#remove_vocab_tag", function () {
      beforeEach(function () {
        $scope.current_word = { vocab_tags: [{name: "one", default_vocab_word_id: 1, id: 4},
                                             {name: "two", id: 4, default_vocab_word_id: 2}],
                                vocab_tags_attributes: [{name: 'one'}, {name: 'two'}] };
        apply_and_flush(); //clear out pending GET requests, as they are not needed here
      });

      describe("when a vocab tag name is not specified", function () {
        beforeEach(function () {
          var tag_to_remove = "two";
          $scope.remove_vocab_tag(tag_to_remove);
        });

        describe("when the first change to the vocab word/vocab tags is removing a vocab tags via the backspace key (triggering a copy on edit)", function () {
          it('finds the latest tag in the vocab_tags_attributes and marks it for deletion', function () {
            expect($scope.current_word.vocab_tags_attributes).toContain({name: 'two', '_destroy': 1});
            expect($scope.current_word.vocab_tags_attributes).not.toContain({name: 'two'});
          });
        });

        describe("when removing a user defined tag/or tag after a copy on edit has occured", function () {
          it('removes the latest vocab_tag from the specified vocab_word', function () {
            expect($scope.current_word.vocab_tags).not.toContain({name: 'two'});
          });

          it('marks the latest vocab_tag for destruction in vocab_tags_attributes', function () {
            expect($scope.current_word.vocab_tags_attributes).toContain({name: 'two', '_destroy': 1});
            expect($scope.current_word.vocab_tags_attributes).not.toContain({name: 'two'});
          });
        });
      });

      describe("when the vocab tag name is specified", function () {
        beforeEach(function () {
          $scope.current_word = {vocab_tags: [{name: "one", default_vocab_word_id: 1, id: 4},
                                               {name: "two", id: 4, default_vocab_word_id: 2}],
                                  vocab_tags_attributes: [{name: 'one'}, {name: 'two'}]};
          $scope.remove_vocab_tag('one');
        });

        describe("when the first change to the vocab word/vocab tags is removing a vocab tag (triggering a copy on edit)", function () {
          it('finds the tag in vocab_tags_attributes and sets it for utter destruction', function () {
            expect($scope.current_word.vocab_tags_attributes).toContain({name: 'one', '_destroy': 1});
          });
        });

        describe("when removing a tag after a copy on edit has occured", function () {
          it("removes that item from vocab_tags for the specified vocab word", function () {
            // words without default_vocab_word_id
            $scope.current_word = {
              vocab_tags: [{name: "three", id: 6},
                           {name: "four", id: 7}],
              vocab_tags_attributes: [{name: 'three'}, {name: 'four'}]
            };
            $scope.remove_vocab_tag('three');

            expect($scope.current_word.vocab_tags.length).toEqual(1);
            expect($scope.current_word.vocab_tags[0]).toEqualData({name: "four", id: 7});
          });

          it("marks that item for destruction in vocab_tags_attributes", function () {
            expect($scope.current_word.vocab_tags_attributes).not.toContain({name: 'one'});
          });
        });
      });
    });


    describe("#save_vocab_tag_changes", function () {
      beforeEach(function () {
        apply_and_flush(); //clear out pending GET requests, as they are not needed here
      });

      it('removes any tags the user has added, not persisted, then deleted ' +
         '(e.g. user types in tag name then immediately backspaces twice to remove tag and blurs out)', function () {
          $scope.current_word = { id: 1, vocab_tags: [{name: "new_tag"}] };
          $scope.current_word.vocab_tags_attributes = [{name: "one", '_destroy': 1}, {name: "new_tag"}];
          var word_spy = spyOn(VocabWord, 'update');
          $scope.save_vocab_tag_changes();

          expect(word_spy).toHaveBeenCalledWith({vocab_word: { vocab_tags_attributes: [{name: "new_tag"}] }, id: 1}, jasmine.any(Function), jasmine.any(Function));
        });

      describe('on success', function () {
        beforeEach(function () {
          $scope.current_word = { id: 1, vocab_tags: [{name: "one"}] };
          $scope.current_word.vocab_tags_attributes = [{name: 'test'}];
          $httpBackend.when('PUT', '/48/vocab_words/1.json').respond(201, { id: 1, vocab_tags: [{ id: 3, name: "one"}] });
          $scope.save_vocab_tag_changes();
          apply_and_flush();  //response from the PUT request
        });

        it('resets vocab tags attributes', function () {
          expect($scope.current_word.vocab_tags_attributes).toEqualData([]);
        });

        it('makes sure the default vocab tag attribute is set to 0', function () {
          expect($scope.current_word.default_vocab_word).toEqual(0);
        });

        it('copies over the attributes returned from the server', function () {
          expect($scope.current_word).toEqualData({ id: 1, vocab_tags: [{ id: 3, name: "one"}], vocab_tags_attributes: [], default_vocab_word: 0 });
        });
      });

      describe("when an error occurs", function () {
        it('shows a dialog with the error messages', function () {
          $scope.current_word = { id: 1, target_word: 'fake word', vocab_tags: [] };
          $scope.current_word.vocab_tags_attributes = [{}];
          var error_spy = spyOn($scope, 'build_error_dialog');
          $httpBackend.when('PUT', '/48/vocab_words/1.json').respond(422, {errors: "error response"});
          $scope.save_vocab_tag_changes();
          apply_and_flush();  //response from the PUT request

          expect(error_spy).toHaveBeenCalledWith('error response');
        });
      });
    });

    describe('#save_recording', function () {
      beforeEach(function () {
        apply_and_flush(); //GET /48/vocab_words
        spyOn($scope, 'update_vocab_word');
        $scope.recorder.recording_path = function () { return 'my/path'; };
      });

      it('saves the vocab word with its recording path', function () {
        $scope.save_recording();

        expect($scope.current_word.recording_path).toEqual('my/path');
        expect($scope.update_vocab_word).toHaveBeenCalledWith($scope.current_word);
        expect($scope.$broadcast).toHaveBeenCalledWith('recording_saved');
      });
    });

    describe('#delete_recording', function () {
      beforeEach(function () {
        apply_and_flush(); //GET /48/vocab_words
        spyOn($scope, 'update_vocab_word');
        spyOn(window, 'confirm').andReturn(true);
        $scope.recorder.recording_path = function () { return 'my/path'; };
      });

      it('deletes the recording and enables record button', function () {
        $scope.delete_recording();

        expect($scope.current_word.recording_path).toEqual('');
        expect($scope.update_vocab_word).toHaveBeenCalledWith($scope.current_word);
        expect($scope.$broadcast).toHaveBeenCalledWith('stop_recorder');
      });
    });

    describe('#find_lesson', function () {
      beforeEach(function() {
        apply_and_flush();
      });

      it('find lesson object from lessons looking by id', function () {
        $scope.lessons = [{id: 1, name: "lesson 1"}, {id: 2, name: "lesson 2"}];
        expect($scope.find_lesson(2)).toEqual( $scope.lessons[1] );
      });
    });

    describe("#update_vocab_word", function () {
      var remove_tags_spy, vocab_word_to_update;
      beforeEach(function () {
        remove_tags_spy = spyOn($scope, 'remove_tags_and_whitespace').andCallThrough();
        apply_and_flush(); //GET /48/vocab_words
        vocab_word_to_update =  { target_word : "one", target_definition : "<br />", base_word : "three" };
        spyOn(_, 'indexOf').andReturn(1);
      });

      it('updates a vocab word', function () {
        //is this enough?
        var update_spy = spyOn(VocabWord, 'update');
        $scope.update_vocab_word(vocab_word_to_update);
        expect(update_spy).toHaveBeenCalled();
      });

      describe('on success', function () {
        beforeEach(function () {
          $httpBackend.when('PUT').respond(200, '');
          $scope.update_vocab_word(vocab_word_to_update);
          apply_and_flush();
        });

        it('cleans any html tags from the base, target or definition', function () {
          expect(remove_tags_spy).toHaveBeenCalled();
        });

        it('replaces original vocab word word, base and definition with entries cleared of <br> and <p>', function () {
          expect(vocab_word_to_update.target_word).toEqual('one');
          expect(vocab_word_to_update.target_definition).toEqual("");
          expect(vocab_word_to_update.base_word).toEqual('three');
        });

        it('stops the recorder', function () {
          expect($scope.$broadcast).toHaveBeenCalledWith('stop_recorder');
        });
      });

      describe("when an error occurs", function () {
        it('shows a dialog with the error messages', function () {
          $httpBackend.when('PUT').respond(500, { errors: 'error response' });
          var error_spy = spyOn($scope, 'build_error_dialog');
          $scope.update_vocab_word(vocab_word_to_update);
          apply_and_flush();

          expect(error_spy).toHaveBeenCalledWith('error response');
        });
      });
    });

    describe("#destroy_image", function () {
      it('notifies that the image is marked for destruction', function () {
        var vocab_word = {};
        apply_and_flush();
        spyOn($scope, 'update_vocab_word');

        $scope.destroy_image(vocab_word);

        expect($scope.update_vocab_word).toHaveBeenCalledWith(vocab_word);
        expect($scope.$broadcast).toHaveBeenCalledWith('image_saved');
        expect(vocab_word._destroy_image).toEqual('1');
      });
    });

    describe("#remove_tags_and_whitespace", function () {
      beforeEach(function () {
        apply_and_flush();
      });

      it('removes any whitespace at the beginning or end of a string', function() {
        var result = $scope.remove_tags_and_whitespace('    hello      ');
        expect(result).toEqual('hello');
      });

      it('removes any tags from a string', function () {
        var result = $scope.remove_tags_and_whitespace('<p>hello&nbsp; </p><br />');
        expect(result).toEqual('hello');
      });

      //TODO: Will there ever be tags we dont want to remove?
      xit('leaves non br and p tag entries alone', function () {
        $scope.find_br_p_entries(control_entry);
        expect(remove_tags_spy).not.toHaveBeenCalled();
      });
    });

    describe("#delete_vocab_word", function () {
      var vocab_word_to_delete;
      beforeEach(function () {
        apply_and_flush();
        vocab_word_to_delete =  { target_word : "one", target_definition : "two", base_word : "three" };
      });

      describe('on success', function () {
        var word_not_to_delete, search_paginate_spy;
        beforeEach(function () {
          word_not_to_delete = { target_word : "a", target_definition : "b", base_word : "c" };
          search_paginate_spy = spyOn($scope, 'search_and_paginate_results');
          $scope.vocab_words = [vocab_word_to_delete, word_not_to_delete];
          $httpBackend.expect('DELETE').respond(200, '');
          $scope.delete_vocab_word(vocab_word_to_delete);
          apply_and_flush();
        });

        it('deletes a vocab word', function () {
          expect($scope.vocab_words).toEqualData([word_not_to_delete]);
        });

        it('search and repaginates', function () {
          expect(search_paginate_spy).toHaveBeenCalled();
        });
      });

      describe("when an error occurs", function () {
        it('shows a dialog with the error messages', function () {
          $httpBackend.when('DELETE').respond(500, { errors: 'error response' });
          var error_spy = spyOn($scope, 'build_error_dialog');
          $scope.delete_vocab_word(vocab_word_to_delete);
          apply_and_flush();

          expect(error_spy).toHaveBeenCalledWith('error response');
        });
      });
    });

    describe("#start_practice", function () {
      var practice_mode = {};
      var shuffle_cards_spy;
      var deal_cards_spy;

      beforeEach(function () {
        shuffle_cards_spy = spyOn($scope, 'shuffle_cards');
        deal_cards_spy = spyOn($scope, 'deal_cards');
        apply_and_flush();
        $scope.start_practice(practice_mode);
      });

      it("sets the practice mode", function () {
        expect($scope.practice_mode).toEqual(practice_mode);
      });

      it("shuffles the vocab cards", function () {
        expect(shuffle_cards_spy).toHaveBeenCalled();
      });

      it("deals vocab cards for the user to practice", function () {
        expect(deal_cards_spy).toHaveBeenCalled();
      });
    });

    describe("#practice_more", function () {
      var shuffle_cards_spy;
      var deal_cards_spy;
      var practice_set_limit = 20;

      beforeEach(function () {
        shuffle_cards_spy = spyOn($scope, 'shuffle_cards');
        deal_cards_spy = spyOn($scope, 'deal_cards');
        apply_and_flush();
      });

      it("deals vocab cards for the user to practice", function () {
        $scope.shuffled_cards = _.range(20);
        $scope.practice_more(practice_set_limit);
        expect(deal_cards_spy).toHaveBeenCalled();
      });

      describe("when there are less than 20 vocab cards left", function () {
        beforeEach(function () {
          $scope.shuffled_cards = _.range(19);
        });

        it("shuffles the vocab word list", function () {
          $scope.practice_more(practice_set_limit);
          expect(shuffle_cards_spy).toHaveBeenCalled();
        });
      });
    });

    describe("#deal_cards", function () {
      beforeEach(function () {
        var practice_mode = {
          name: 'Test Practice Mode',
          build_card: jasmine.createSpy('build_card').andReturn({}),
          practice_set_limit: 9
        };
        apply_and_flush();
      });

      xit("knows how big the practice set is", function () {
      });

      xit("removes the next 20 vocab cards from the shuffled cards list", function () {
      });
    });


    describe("#build_practice_cards", function () {
      var practice_mode;

      beforeEach(function () {
        practice_mode = {
          name: 'Test Practice Mode',
          build_card: jasmine.createSpy('build_card').andReturn({})
        };
        apply_and_flush();
      });

      it("builds a list of practice cards using the practice mode's build strategy", function () {
        $scope.practice_mode = practice_mode;
        $scope.vocab_words = _.range(5);
        $scope.search_results = _.range(3);
        expect($scope.build_practice_cards().length).toEqual(3);
        expect(practice_mode.build_card.calls.length).toEqual(3);
      });
    });

    describe("#shuffle_cards", function () {
      beforeEach(function () {
        apply_and_flush();
      });

      it("creates a shuffled list of vocab words", function () {
        var vocab_words = [];
        var shuffle_spy = spyOn(_, 'shuffle').andCallThrough();
        var build_cards_spy = spyOn($scope, 'build_practice_cards').andReturn(vocab_words);
        $scope.shuffle_cards();

        expect(build_cards_spy).toHaveBeenCalled();
        expect(shuffle_spy).toHaveBeenCalledWith(vocab_words);
      });
    });

    describe("#build_error_dialog", function () {
      var dialog_spy, text_spy;
      beforeEach(function () {
        dialog_spy = spyOn($.fn, "dialog");
        //TODO figure out how to test the error text is ok
        //text_spy = spyOn($.fn, "text");
        apply_and_flush();
      });

      it("creates a dialog", function () {
        $scope.build_error_dialog("more error text");
        //expect(text_spy).toHaveBeenCalled();
        expect(dialog_spy).toHaveBeenCalled();
      });
    });

    describe("#has_multiple_programs", function () {
      beforeEach(function () {
        apply_and_flush();
        $scope.lessons = [{program_name: "program 1", name: "lesson 1"},
                          {program_name: "program 1", name: "lesson 1"}];
        });

      it('returns false if there are lessons only for one program', function (){
        expect($scope.has_multiple_programs()).toBeFalsy();
      });

      it('returns true if there are lessons for multiple programs', function (){
        $scope.lessons.push({program_name: "program 2", name: "lesson 1"});
        expect($scope.has_multiple_programs()).toBeTruthy();
      });
    });

    describe("#programs_counter", function () {
      beforeEach(function () {
        apply_and_flush();
        $scope.lessons = [{program_name: "program 1", name: "lesson 1"},
                          {program_name: "program 1", name: "lesson 1"},
                          {program_name: "program 2", name: "lesson 1"}];
      });

      it('returns how many programs the user has access to', function () {
        expect($scope.programs_counter()).toEqual(2);
      });

      it('assign programs_size with number of accessible programs', function () {
        $scope.programs_counter();
        expect($scope.programs_size).toEqual(2);
      });
    });

    describe("#filtered_lessons", function () {
      beforeEach(function() {
        apply_and_flush();
      })

      it('returns an array with only valid lessons', function () {
        var lessons = [{program_name: 'program 1', label: 'label 1', name: 'lesson 1'}];
        $scope.filtered_lessons(lessons);

        var lesson_names = _.pluck($scope.lessons, 'name');
        expect(lesson_names).toEqual(['label 1']);
      });

      it('returns an array using labels instead names if they are defined', function () {
        var lessons = [{program_name: 'program 1', label: 'label 1', name: 'lesson 1'},
                       {program_name: 'program 1', label: 'label 2', name: 'Lesson 2'}];
        $scope.filtered_lessons(lessons);

        var lesson_names = _.pluck($scope.lessons, 'name');
        expect(lesson_names).toEqual(['label 1', 'label 2']);
      });

      it('returns an array using names if labels are not defined', function () {
        var lessons = [{program_name: 'program 1', label: '', name: 'lesson 1'},
                       {program_name: 'program 1', label: '', name: 'lesson 2'}];
        $scope.filtered_lessons(lessons);

        var lesson_names = _.pluck($scope.lessons, 'name');
        expect(lesson_names).toEqual(['lesson 1', 'lesson 2']);
      });
    });

    describe("$search_filter", function () {
      var words;
      beforeEach(function () {
        apply_and_flush();
      });

      it('is defined', function () {
        expect($filter('search_filter')).not.toBeNull();
      });

      it('is case insensitive', function () {
        words = [{id: 1, target_word: 'TargeT WorD 1', vocab_tags: [] },
                 {id: 2, target_word: 'target word 2', vocab_tags: [] }];
        expect($filter('search_filter')(words, 'target word 1')).toEqual([ words[0] ]);
      });

      it('includes accented characters and their english equivalent', function () {
        words = [{id: 1, target_word: 'TargeT WorD 1 állo', vocab_tags: [] },
                 {id: 2, target_word: 'target word 2', vocab_tags: [] } ];
        expect($filter('search_filter')(words, 'target word 1 allo')).toEqual([ words[0] ]);
      });

      describe("when all the words in search box are contained in a vocab_word's tags", function () {
        it('includes that vocab_word in the results', function () {
          words = [{id: 1, target_word: 'target word 1', vocab_tags: [{name: 'tag'}, {name: '1'}, {name: 'blah'}] },
                   {id: 2, target_word: 'target word 2', vocab_tags: [{name: 'tag'}, {name: '2'}] } ];
          expect($filter('search_filter')(words, 'tag 1')).toEqual([ words[0] ]);
        });
      });

      describe("when lesson is selected", function () {
        beforeEach(function () {
          apply_and_flush;
          $scope.vocab_words = [{id: 1, base_word: 'aaa', lesson_id: 1, vocab_tags: [] },
                                {id: 2, base_word: 'bbb', lesson_id: 2, vocab_tags: [] },
                                {id: 3, base_word: 'ccc', lesson_id: 2, vocab_tags: [] }];
        });

        it('assign and show only vocab words for an specific lesson', function () {
          $scope.searcher_selected_lesson = {"id": 2, "program_name": "panorama", "lesson_name": "one name"};
          $scope.$digest();
          expect($scope.search_results).toEqual([ $scope.vocab_words[1], $scope.vocab_words[2] ]);
        });

        it('assign vocab words filtering by lesson and search_term', function () {
          $scope.searcher_selected_lesson = {"id": 2, "program_name": "panorama", "lesson_name": "other name"};
          $scope.search_term = "c";
          $scope.$digest();
          expect($scope.search_results).toEqual([ $scope.vocab_words[2] ]);
        });
      });

      describe("when any of the words in the search box are contained in the vocab_word's base_word ", function () {
        it('includes that vocab_word in the results', function () {
          words = [{id: 1, base_word: 'base word 1', vocab_tags: [] },
                   {id: 2, base_word: 'base word 2', vocab_tags: [] }];
          expect($filter('search_filter')(words, 'base word 1')).toEqual([ words[0] ]);
        });
      });

      describe("when any of the words in the search box are contained in the vocab_word's target_word ", function () {
        it('includes that vocab_word in the results', function () {
          words = [{id: 1, target_word: 'target word 1', vocab_tags: [] },
                   {id: 2, target_word: 'target word 2', vocab_tags: [] } ];
          expect($filter('search_filter')(words, 'target word 1')).toEqual([ words[0] ]);
        });
      });

      describe("when any of the words in the search box are contained in the vocab_word's target_definition ", function () {
        it('includes that vocab_word in the results', function () {
          words = [{id: 1, target_definition: 'target definition 1', vocab_tags: [] },
                   {id: 2, target_definition: 'target definition 2', vocab_tags: [] } ];
          expect($filter('search_filter')(words, 'target definition 1')).toEqual([ words[0] ]);
        });
      });
    });
  });
});
