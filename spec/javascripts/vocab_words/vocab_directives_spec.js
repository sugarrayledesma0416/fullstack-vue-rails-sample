//= require fine_uploader/fine_uploader_directive
//= require angular-resource
//= require vocab_words/vocab_words_app_bootstrap
//= require vocab_words/directives/vt_accent_blur
//= require maestro_activity_engine/vhl_ng/bootstrap 



describe('vocab_ui', function() {
var elm, $scope, $compile;
  beforeEach(module('vocab_words_app'));
  beforeEach(inject(function($injector) {
    $scope = $injector.get('$rootScope');
    $compile = $injector.get('$compile');
  }));

  describe("#vtAccentBlur", function() {
    beforeEach(function(){
      elm = angular.element(
        '<div><input ng-model="foo" vt-accent-blur />'+
        '<div id="accent_bar"></div></div>'
        );
      $scope.foo = 'cat';
      $scope.update_vocab_word = jasmine.createSpy('update_vocab_word');
      $compile(elm)($scope);
      $scope.$digest();
    });

    //scenarios:
    //click inside content editable div, immediately click out, no changes were made, no update should occur
    //click inside content editable div, click accent bar, accent should be added, no update should fire
    //click inside content editable div, click accent bar, click out, update should fire
    //click inside content editable div, make a change with keyboard, click out, update should fire
    describe("when the accent bar has been clicked", function() {
      it('does not send a PUT request to persist the vocab word', function() {
        var data_spy = spyOn($.fn, 'data').andReturn(true);
        elm.find('input').trigger('blur');
        expect(data_spy).toHaveBeenCalledWith('accentClicked');
        expect($scope.update_vocab_word).not.toHaveBeenCalled();
      });
    });

    describe("when anything but the accent bar is clicked and there were changes made", function() {
      it('persists the word to the db via a PUT request', function() {
        var data_spy = spyOn($.fn, 'data').andReturn(false);
        elm.find('input').trigger('blur');
        expect($scope.update_vocab_word).toHaveBeenCalled();
      });
    });
   });

  describe('#wordAttribute', function () {
    beforeEach(inject(function ($injector) {
      $scope = $injector.get('$rootScope');
      $compile = $injector.get('$compile');

      var fixture = "<div>\
        <input type='text' ng-model='blah' word-attribute />\
      </div>";
      elm = $compile(fixture)($scope);
      elm = elm.find('input');
    }));

    it('calls setViewValue function in order to set controller ng-model', function () {
      var ctrl = elm.controller('ngModel');
      spyOn(ctrl, '$setViewValue');

      elm.trigger('accented_character_added');
      expect(ctrl.$setViewValue).toHaveBeenCalled();
    });
  });

  describe('#isDisabled', function() {
    beforeEach(function(){
      elm = angular.element(
        '<div><input ng-model="foo" is-disabled class="fart" />'+
        '<input type="submit" ng-disabled="add_word_disabled" /></div>'
        );
      $scope.foo = 'cat'
      $scope.add_word_disabled = true;
      $compile(elm)($scope);
      $scope.$digest();
    });
    //TODO not sure how to test this.
    it('enables submit button when one field has text in it', function() {
      var input = elm.find('.fart')
      input.val('fart')
      input.trigger('input')
      input.trigger('change')//bwowsah compatibility
      expect($scope.add_word_disabled).toBe(false)
    })
  });

  describe('#overflowService', function() {
    var overflow_service, long_text;

    beforeEach(inject(function(overflowService){

      //the length of long_text is 175
      long_text = "Of names of this kind, I can give you a quorum,"+
      "Such as Munkustrap, Quaxo, or Coricopat,"+
      "Such as Bombalurina, or else Jellylorum-"+
      "Names that never belong to more than one cat!!!!"

      overflow_service = overflowService;
      elm = angular.element(
        '<div><div class="inner">'+long_text+'</div></div>'
        );
    }));

    //TODO figure out where to put & how to test trim_entry
    //and if we even need it...
    it('truncates text that is > 100 chars', function() {
      overflow_service.create_hover(elm);
    //add 3 to 100 because of ellipses.
      expect(elm.find('.inner').text().length).toBe(103);
    });

    it('creates a hover with the overflow text', function() {
      overflow_service.create_hover(elm);
      var overflow_text = elm.siblings().find('.overflowed_text').text()
      expect(overflow_text.length).toBe(75);
    });

    it('hides the hover initially', function() {
      overflow_service.create_hover(elm);
      var hoverdiv = elm.siblings().find('.overflowed_text');
      expect(hoverdiv).toBeHidden();
    });

    it('binds a hover to the element to show the overflow hover', function() {
      overflow_service.create_hover(elm);
      expect(elm).toHandle('mouseover');
      expect(elm).toHandle('mouseout');
    });
  });

  describe('#vocabUIHelpers', function() {
    var vocab_helpers;

    beforeEach(inject(function(vocabUIHelpers){
      vocab_helpers = vocabUIHelpers;
    }));

  });

  describe('#toggleable', function() {
    var drop_control;

    beforeEach(function(){
      elm = angular.element(
        '<tbody toggleable><tr class="vocab_record"><td class="drop_control"></td></tr><tr class="record_details"></tr></tbody>'
        );

      drop_control = elm.find('.drop_control');
      $compile(elm)($scope);
      $scope.$digest();
    });

    it('should bind a click to .drop_control', function() {
      expect(drop_control).toHandle('click');
    });

    it('should hide the details row initially', function() {
      expect(elm).not.toHaveClass('open_row');
    });

    xdescribe('when the row is closed', function() {
      it('clicking toggleable should open it', function() {
        drop_control.click();
        expect($scope.$emit).toHaveBeenCalled()
      });
    });

    xit('clicking should toggle the open_row class', function() {
      elm.removeClass('open_row');
      drop_control.click();
      expect(elm).toHaveClass('open_row');

      elm.addClass('open_row');
      drop_control.click();
      expect(elm).not.toHaveClass('open_row');
    });
  });

  describe('#ngvocabcard', function() {
    var card, vocab_helpers_spy, overflow_spy;

    beforeEach(function(){
      elm = angular.element(
        '<div ngvocabcard>'+
        '<div class="word">'+
        '<div class="card_a_outer"><div class="inner">foo</div></div>'+
        '<div class="card_b_outer"><div class="inner">bar</div></div>'+
        '</div>'+
        '<div class="vocab_card_overflow_hover"></div>'+
        '</div>'
        );

      $compile(elm)($scope);
      $scope.$digest();

    });

    beforeEach(inject(function(vocabUIHelpers, overflowService){
      card = {
        flipped: false,
      hidden_text: "Jellylorum"
      }
      vocab_helpers_spy = spyOn(vocabUIHelpers, 'getCardAttrs').andReturn(card);
      overflow_spy = spyOn(overflowService, 'create_hover');
    }));

    describe('when a card is clicked', function() {

      it('removes the hover for a card that has been clicked', function() {
        var hoverdiv = elm.find('.vocab_card_overflow_hover');
        expect(elm.find('.vocab_card_overflow_hover').length).toBe(1);
        elm.click();
        expect(elm.find('.vocab_card_overflow_hover').length).toBe(0);
      });

      it('if card.flipped is false, change it to true', function() {
        card.flipped = false;
        elm.click();
        expect(card.flipped).toBe(true);
      });

      it('replaces "front" text of card with "back" text', function() {
        var card_text_a = elm.find('.word .card_a_outer .inner');
        var card_text_b = elm.find('.word .card_b_outer .inner');
        expect(card_text_a.text()).toBe('foo');
        expect(card_text_b.text()).toBe('bar');
        elm.click();
        expect(card_text_a.text()).toBe('Jellylorum');
        expect(card_text_b.text()).toBe('');
      });

      it('adds flipped class to the card', function() {
        expect(elm).not.toHaveClass('flipped');
        elm.click();
        expect(elm).toHaveClass('flipped');
      });

      it('creates a hover for the back of the card', function() {
        elm.click();
        expect(overflow_spy).toHaveBeenCalled();
        //TODO test that a new overflow hover has been shown.
      });

    });
  });

  describe('#vocabvalidate', function() {
    var vocab_word_mock;

    beforeEach(function(){
      elm = angular.element(
        '<div vocabvalidate ng-model="vocab_word.target_word">foo</div>'
        );

      $compile(elm)($scope);
      $scope.$digest();
    });

    beforeEach(function() {

    });
    xit('', function() {
      //TODO figure out how to test this.
    });
  });

  describe('#tag', function() {

    beforeEach(function(){
      elm = angular.element(
        '<div><li tag></li>' +
         ' <li><input type="text" /></li></div>'
        );

      $compile(elm)($scope);
      $scope.$digest();
    });

    it('handles a click event', function() {
      expect(elm.find('[tag]')).toHandle('click');
    });

    describe("when the user clicks on the tag (not the x)", function() {
      it('focuses on the new tag input field', function() {
        var focus_spy = spyOn($.fn, 'focus')
        elm.find('[tag]').trigger('click')
        expect(focus_spy).toHaveBeenCalled();
      });
    });
  });

  describe("#removeTag", function() {
    beforeEach(function(){
      elm = angular.element(
        '<div>'+
        ' <ul>'+
        '  <li>'+
        '   <span class="tag-text">Text</span><span remove-tag></span>'+
        '  </li>' +
        '  <li class="new-tag">'+
        '   <input type="text" new-tag ng-model="foo" />' +
        '  </li>' +
        ' </ul>' +
        '</div>'
        );

      $scope.vocab_word = {id: 1, vocab_tags: [{id: 1, name: 'default_tag_1', default_vocab_word_id: 1}] }
      $scope.build_error_dialog = function () {};
      $scope.save_vocab_tag_changes = function(){}
      $scope.remove_vocab_tag = function(){}
      $scope.add_vocab_tag = function(){}

      $compile(elm)($scope);
      $scope.$digest();
    });

    it('handles a mousedown event', function() {
      expect(elm.find('[remove-tag]')).toHandle('mousedown');
    });

    it('calls the remove vocab tag method', function() {
      spyOn($scope, 'remove_vocab_tag')
      elm.find('[remove-tag]').trigger('mousedown');
      expect($scope.remove_vocab_tag).toHaveBeenCalledWith(elm.find('.tag-text').html());
    });

    it('calls the save_vocab_tag_changes method', function() {
      spyOn($scope, 'save_vocab_tag_changes')
      elm.find('[remove-tag]').trigger('mousedown');
      expect($scope.save_vocab_tag_changes).toHaveBeenCalled();
    });

    it('deletes tags on the first click', function () {
      elm.find('ul').trigger('focusout')
      elm.find('[remove-tag]').trigger('mousedown');
    });

    describe("when we have added new tags that are not persisted to the db yet", function() {
      describe("and the new tag input is focused", function() {
        // In order for this test to pass, we need to upgrade to jQuery 1.9 due the order of focus/blur events firing
        xdescribe("when we click the removeTag 'x' on a tag", function() {
          beforeEach(inject(function($injector) {
            var $timeout = $injector.get('$timeout')
            spyOn($scope, 'add_vocab_tag')
            elm.find('input').trigger('blur')
            elm.find('[remove-tag]').trigger('mousedown')
            $timeout.flush()
          }));

          xit('does not call add_vocab_tag', function() {
            expect($scope.add_vocab_tag).not.toHaveBeenCalled();
          });

          xit('sets the vocabTagClicked data attr on the new-tag input', function() {
            expect(elm.find('input').data('removeTagClicked')).toBeTruthy();
          });
        });
      });
    });

    describe('when the input element is focused but the tag has not been committed', function () {
      beforeEach(inject(function($injector) {
        spyOn($scope, 'build_error_dialog');
        spyOn($scope, 'add_vocab_tag');
        spyOn($scope, 'remove_vocab_tag');

        var $timeout = $injector.get('$timeout');

        elm.find('[new-tag]').val('foo');
        elm.find('input').trigger('blur');
        elm.find('[remove-tag]').trigger('mousedown');

        $timeout.flush();
      }));

      it('does not throw a "name has already been used" error', function () {
        expect($scope.build_error_dialog).not.toHaveBeenCalled();
      });

      it('does not call add_vocab_tag', function () {
        expect($scope.add_vocab_tag).not.toHaveBeenCalled();
      });

      it('calls remove_vocab_tag', function () {
        expect($scope.remove_vocab_tag).toHaveBeenCalled();
      });

      it('leaves the uncommitted tag as-is', function () {
        expect(elm.find('[new-tag]').val()).toEqual('foo');
      });
    });

  });

  describe("#newTag", function() {
    var $timeout
    beforeEach(function(){
      inject(function($injector){
        $timeout = $injector.get('$timeout')
      })

      elm = angular.element(
        '<div>'+
        ' <ul>'+
        '  <li class="new-tag">'+
        '   <input type="text" ng-model="foo" new-tag />'+
        '  </li>' +
        ' </ul>' +
        '</div>'
        );

      $scope.vocab_word = {id: 1, vocab_tags: [{id: 1, name: 'default_tag_1', default_vocab_word_id: 1}] }
      $compile(elm)($scope);
      $scope.$digest();
    });

    it('copies any default vocab words into the vocab_tags_attributes for a given word', function() {
      expect($scope.vocab_word.vocab_tags_attributes).toEqual([{ name: 'default_tag_1' }])
    });

    it('handles a blur event', function() {
      expect(elm.find('input')).toHandle('blur');
    });

    it('handles a focus event', function() {
      expect(elm.find('input')).toHandle('focus');
    });

    describe("when a user focuses in the input", function() {
      it('resets the removeTagClicked data attr to false', function() {
        elm.find('input').data('removeTagClicked', true)
        elm.find('input').focus()
        $timeout.flush()
        expect(elm.find('input').data('removeTagClicked')).toBeFalsy();
      });
    });

    describe("when the user clicks out of the new-tag input", function() {
      beforeEach(function(){
        $scope.add_vocab_tag = function(){}
        $scope.save_vocab_tag_changes = function(){}
        $scope.new_vocab_tag = {}
      });

      describe("when there are tags marked with _destroy in vocab_tags_attributes", function() {
        describe("when the new_tag input field is blank", function() {
          beforeEach(function(){
            $scope.vocab_word.vocab_tags_attributes = [{name: 'one', '_destroy': 1}]
          })
          it('makes a PUT request to persist the deletions to the db', function() {
            spyOn($scope, 'save_vocab_tag_changes')
            elm.find('input').trigger('blur')
            $timeout.flush()
            expect($scope.save_vocab_tag_changes).toHaveBeenCalled();
          });

          it('does not call add_vocab_tag', function() {
            spyOn($scope, 'add_vocab_tag')
            elm.find('input').trigger('blur')
            $timeout.flush()
            expect($scope.add_vocab_tag).not.toHaveBeenCalled();
          });
        });
      });

      describe("when there are no tags marked with _destroy, but there is text in the new tag input field", function() {
        beforeEach(function(){
          elm.find('input').val('something')
        })
        describe("when the user did not click on a removeTag 'x'", function() {
          it('adds a vocab tag', function() {
            spyOn($scope, 'add_vocab_tag')
            elm.find('input').trigger('blur')
            $timeout.flush()
            expect($scope.add_vocab_tag).toHaveBeenCalled();
          });

          it('persists the changes to the db', function() {
            spyOn($scope, 'save_vocab_tag_changes')
            elm.find('input').trigger('blur')
            $timeout.flush()
            expect($scope.save_vocab_tag_changes).toHaveBeenCalled();
          });
        });
      });

      describe("when the user did click on a removeTag 'x'", function() {
        it('does not call add_vocab_tag', function() {
          elm.find('input').data('removeTagClicked', true)
          spyOn($scope, 'add_vocab_tag')
          elm.find('input').trigger('blur')
          $timeout.flush()
          expect($scope.add_vocab_tag).not.toHaveBeenCalled();
        });

        it('does not call save_vocab_tag_changes', function() {
          elm.find('input').data('removeTagClicked', true)
          spyOn($scope, 'save_vocab_tag_changes')
          elm.find('input').trigger('blur')
          $timeout.flush()
          expect($scope.save_vocab_tag_changes).not.toHaveBeenCalled();
        });
      });
    });

    describe("when the user presses a key in the input field", function() {
      beforeEach(function(){
        $scope.save_vocab_tag_changes = function(){}
      })

      describe("when the key pressed is a comma", function() {
        it('adds a vocab tag', function() {
          e = $.Event('keydown');
          e.which = 188; // A comma
          $scope.add_vocab_tag = jasmine.createSpy('add_vocab_tag_spy')
          elm.find('input').trigger(e);
          expect($scope.add_vocab_tag).toHaveBeenCalled();
          expect(elm.find('input').val()).toBe('');
        });
      });

      describe("when the key pressed is enter", function() {
        it('adds a vocab tag', function() {
          e = $.Event('keydown');
          e.which = 13; // An enter
          $scope.add_vocab_tag = jasmine.createSpy('add_vocab_tag_spy')
          elm.find('input').trigger(e);
          expect($scope.add_vocab_tag).toHaveBeenCalled();
        });
      });

      describe("when the key pressed is backspace", function() {
        it('sets the last character deleted tracker', function() {
          e = $.Event('keydown');
          e.which = 8; // A backspace
          var val_spy = spyOn($.fn, 'val');
          elm.find('input').trigger(e);
          expect(val_spy).toHaveBeenCalled();
        });
      });

      describe("when any key is pressed", function() {
        it('sets the current character position for the accent bar', function() {
          e = $.Event('keyup');
          e.which = 33; // A backspace
          spyOn(VHL.AccentBar, 'set_current_caret_position');
          elm.find('input').trigger(e);
          expect(VHL.AccentBar.set_current_caret_position).toHaveBeenCalled();
        });
      });

      describe("when deleting a vocab tag", function() {
        var keydown, keyup;
        beforeEach(function() {
          keydown = $.Event('keydown');
          keydown.which = 8; // A backspace
          keyup = $.Event('keyup');
          keyup.which = 8
          spyOn($.fn, 'val').andReturn("");
        });

        describe("when backspace is pressed once", function() {
          it('sets the background of the last tag to an alert color', function() {
            elm.find('input').trigger(keydown);
            var css_spy = spyOn($.fn, 'css')
            elm.find('input').trigger(keyup)
            expect(css_spy).toHaveBeenCalledWith({'background-color': 'red', 'color': 'white'});
          });
        });

        describe("when backspace is pressed twice", function() {
          it('removes the last vocab tag', function() {
            $scope.remove_vocab_tag = jasmine.createSpy('remove_vocab_tag_spy')
            elm.find('input').trigger(keydown);
            elm.find('input').trigger(keyup);
            elm.find('input').trigger(keyup);
            expect($scope.remove_vocab_tag).toHaveBeenCalledWith($scope);
          });
        });

        describe("when the backspace is pressed then the user continues typing", function() {
          it('unsets backspace tracker', function() {
            var keyupletter = $.Event('keyup');
            keyupletter.which = 97;
            elm.find('input').trigger(keydown);
            elm.find('input').trigger(keyup);
            elm.find('input').trigger(keyupletter);
            expect(elm).not.toHaveCss({color: "white"});
          });
        });

      });
    });
  });

  describe("shows UI changes to indicate what is sorted", function() {
    beforeEach(function(){
      elm = angular.element(
        '<div>'+
        ' <li>'+
        '  <span class="tag-text">Text</span><span remove-tag></span>'+
        ' </li>' +
        '</div>'
        );

      $scope = $rootScope;
      $compile(elm)($scope);
      $scope.$digest();
    });

  });

  describe("#searchInput", function () {
    beforeEach(function () {
      elm = angular.element('<input type="text" ng-model="foo" search-input /></div>');
      $compile(elm)($scope);
      $scope.$digest();

      $scope.search_results = 'foo';
      $scope.vocab_words = 'bar';

      $scope.search_and_paginate_results = function () {};
      search_spy = spyOn($scope, 'search_and_paginate_results');

      e = $.Event('keyup');
    });

    it('does nothing when a "no action" character is pressed', function () {
      e.which = 16; // Shift
      $(elm[0]).trigger(e);

      expect(search_spy).not.toHaveBeenCalled();
      expect($scope.search_results).toEqual('foo');
    });

    it('resets the search pool and paginates the results when backspace is entered', function() {
      $scope.search_by_lesson = function () {};
      e.which = 8; // Backspace
      $(elm[0]).trigger(e);

      expect(search_spy).toHaveBeenCalled();
      expect($scope.search_results).toEqual($scope.vocab_words);
    });

    it('searches and paginates results when a character is entered', function() {
      e.which = 77; // An "M"
      $(elm[0]).trigger(e);

      expect(search_spy).toHaveBeenCalled();
    });

  });
  describe('when there are drop down menus', function() {
    describe('vtCloseDropDowns', function() {
      beforeEach(function() {
        elm = angular.element('<div vt-close-drop-downs><div data-js-dropdown id="capturetest"></div></div>');
        $compile(elm)($scope);
        $scope.$digest();
      });
      it('should close any menus when it is clicked on.', function(){
        elm.click();
        expect($(elm).find('#capturetest')).toHaveClass('menu-closed');
      });
    });

    describe('vtDropDownContainer', function() {
      beforeEach(function() {
        elm = angular.element('<div vt-drop-down-container><div data-js-dropdown id="containertest" class="menu-closed"></div></div>');
        $compile(elm)($scope);
        $scope.$digest();
      });
      it('should open the dropdown menu it contains.', function(){
        elm.click();
        expect($(elm).find('#containertest')).not.toHaveClass('menu-closed');
      });
    });

    describe('vtDropDownMenu', function() {
      beforeEach(function() {
        elm = angular.element('<div vt-drop-down-menu data-js-dropdown ></div>');
        $compile(elm)($scope);
        $scope.$digest();
      });
      it('initialize itself as closed', function(){
        expect($(elm)).toHaveClass('menu-closed');
      });
      it('close itself when clicked on', function(){
        elm.removeClass('menu-closed');
        elm.click();
        expect($(elm)).toHaveClass('menu-closed');
      });
    });
  });
  describe("vt-add-word-success-msg", function() {
    beforeEach(function() {
      $scope.add_word_success_enabled = false;
      elm = angular.element('<div vt-add-word-success-msg="add_word_success_enabled" ></div>');
      $compile(elm)($scope);
      $scope.$digest();
    });

    beforeEach(inject(function($injector) {
      $timeout = $injector.get('$timeout');
      jQuery.fx.off = true;
    }));

   xit('displays a message for several seconds after a word is added during a search', function(){
      $scope.$apply(function() {
        $scope.search_term = "foo";
        $scope.add_word_success_enabled = true;
      });

      $timeout.flush();
     //TODO unsure of how to test for opacity here.
     //jQuery.fx.off must be true in order for $timeout to fire
     //Might be solveable with angular upgrade and use of ngAnimation
   });
    it('resets new word added flag back to false', function(){
      $scope.$apply(function() {
        $scope.search_term = "foo";
        $scope.add_word_success_enabled = true;
      });
      expect($scope.add_word_success_enabled).toEqual(false);
    });
  });


});
