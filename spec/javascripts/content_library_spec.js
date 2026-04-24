//= require content_library
//= require assignment_wizard

describe("VHL.ContentLibrary", function(){
  var activity_id, program_id, section_id;

  beforeEach(function () {
    activity_id = 5;
    program_id = 48;
    section_id = '270075';
    spyOn($, 'post').andReturn({ done: function(){} });
    appendSetFixtures('<meta name="VHL.program_id" content="' + program_id + '"/>');
    appendSetFixtures('<meta name="VHL.section_id" content="' + section_id + '"/>');
    appendSetFixtures('<a href="#" data-activity-view="hide" data-activity-id="' + activity_id + '">Remove from student view</a>');
    appendSetFixtures('<a href="#" data-activity-view="show" data-activity-id="' + activity_id + '">Remove from student view</a>');
    appendSetFixtures('<div data-modal="content_library" class="dialog"/>');
    VHL.Checkboxes = { _selected_activity_ids: function() { return [activity_id]; } };
    VHL.ContentLibrary.init();
  });

  describe('#hide_activity', function () {
    it('executes an Ajax request to hide the activity from the student view', function () {
      $('[data-activity-view="hide"]').trigger('click');
      expect($.post).toHaveBeenCalledWith('/instructor/' + program_id + '/activities/hide',
        { activity_id: [activity_id], section_id: section_id });
    });
  });

  describe('#unhide_activity', function () {
    it('executes an Ajax request to unhide the activity from the student view', function () {
      $('[data-activity-view="show"]').trigger('click');
      expect($.post).toHaveBeenCalledWith('/instructor/' + program_id + '/activities/unhide',
        { activity_id: [activity_id], section_id: section_id });
    });
  });

  describe('#assignment_wizard', function () {
    var assignment_link;

    beforeEach(function () {
      spyOn($.fn, 'dialog');
      assignment_link = $('<a>assign</a>');
      spyOn($.fn, 'assignment_wizard');
    });

    describe('with selected hidden activites', function () {
      beforeEach(function () {
        spyOn(VHL.ContentLibrary, '_any_hidden_selected').andCallFake( function() { return true; } );
      });

      it('displays a jquery modal if hidden activites are selected', function () {
        VHL.ContentLibrary.assignment_wizard(assignment_link);
        expect($.fn.dialog).toHaveBeenCalled();
      });

      it('does not call the call the assignment wizard immediately', function () {
        VHL.ContentLibrary.assignment_wizard(assignment_link);
        expect(assignment_link.assignment_wizard).not.toHaveBeenCalled();
      });
    });

    describe('without any hiddent activities selected', function () {
      beforeEach(function () {
        spyOn(VHL.ContentLibrary, '_any_hidden_selected').andCallFake( function() { return false; } );
      });

      it('does not display a jquery modal if hidden activites are not selected', function () {
        VHL.ContentLibrary.assignment_wizard(assignment_link);
        expect($.fn.dialog).not.toHaveBeenCalled();
      });

      it('calls the assignment wizard immediately', function () {
        VHL.ContentLibrary.assignment_wizard(assignment_link);
        expect(assignment_link.assignment_wizard).toHaveBeenCalled();
      });
    });
  });


  describe('#_hide_activity_with_confirmation', function () {

    beforeEach(function () {
      spyOn($.fn, 'dialog');
      spyOn(VHL.ContentLibrary, '_hide_activity');
    });

    describe('with assigned activities selected', function () {
      beforeEach(function () {
        spyOn(VHL.ContentLibrary, '_any_assigned_activity_selected').andCallFake( function() { return true; } );
      });

      it('displays a jquery modal if assigned activites are selected', function () {
        VHL.ContentLibrary._hide_activity_with_confirmation(program_id, section_id);
        expect($.fn.dialog).toHaveBeenCalled();
      });

      it('does not call hide_activity', function () {
        VHL.ContentLibrary._hide_activity_with_confirmation(program_id, section_id);
        expect(VHL.ContentLibrary._hide_activity).not.toHaveBeenCalled();
      });
    });

    describe('without any assigned activity selected', function () {
      beforeEach(function () {
        spyOn(VHL.ContentLibrary, '_any_assigned_activity_selected').andCallFake( function() { return false; } );
      });

      it('does not display a jquery modal if hidden activites are not selected', function () {
        VHL.ContentLibrary._hide_activity_with_confirmation(program_id, section_id);
        expect($.fn.dialog).not.toHaveBeenCalled();
      });

      it('calls hide_activity', function () {
        VHL.ContentLibrary._hide_activity_with_confirmation(program_id, section_id);
        expect(VHL.ContentLibrary._hide_activity).toHaveBeenCalled();
      });
    });
  });

});
