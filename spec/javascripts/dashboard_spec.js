//= require dashboard


describe('VHL.Dashboard', function(){
  beforeEach(function() {
    loadFixtures('instructor_dashboard.html');
    VHL.focus = {
      update_focus: function() {}
    };
  });

  describe('when the focus is on a section', function() {
    beforeEach(function() {
      appendSetFixtures('<div id="focus_indicator" data-js-focus=\'{"course": 123,"section": 456}\'></div>');
      VHL.Dashboard.init();  
    });

    it('does not add a class to the right course header', function() {
      expect($('#course_header')).not.toHaveClass('program-header-bar');
    });

    it('adds a class to style the right focused section header', function() {
      expect($('#section_header_focused')).toHaveClass('program-header-bar');
      expect($('#section_header_focused')).not.toHaveClass('neutral-header-bar');
      expect($('#section_header_focused')).not.toHaveClass('bar-hover');
    });

    it('adds a class to style the right side section header', function() {
      expect($('#section_456')).toHaveClass('program-header-bar');
      expect($('#section_456')).not.toHaveClass('bar-hover');
      expect($('#section_456')).not.toHaveClass('neutral-header-bar');
    });
  });
  
  describe('when the focus is on a course', function() {
    beforeEach(function() {
      appendSetFixtures('<div id="focus_indicator" data-js-focus=\'{"course": 123,"section": null}\'></div>');
      VHL.Dashboard.init();  
    });

    it('Adds a class to style the left side course header', function() {
      expect($('#course_header')).toHaveClass('program-header-bar');
      expect($('#course_header')).not.toHaveClass('neutral-header-bar');
      expect($('#course_header')).not.toHaveClass('bar-hover');
    });
    
    it('Adds a class to style the right side course header', function() {
      expect($('.grading_task_section')).toHaveClass('program-header-bar');
      expect($('.grading_task_section')).not.toHaveClass('neutral-header-bar');
      expect($('.grading_task_section')).not.toHaveClass('bar-hover');
    });
  });

  describe('when a section link is clicked on the left side', function() {
    beforeEach(function() {
      appendSetFixtures('<div id="focus_indicator" data-js-focus=\'{"course": 123,"section": 456}\'></div>');
      VHL.Dashboard.init();  
    });

    it('removes program-header-bar class from all course headers', function() {
      $('#course_header, .grading_task_section').addClass('program-header-bar').
        removeClass('neutral-header-bar bar-hover');
      $('#clicked_section').click();
      expect($('#course_header')).not.toHaveClass('program-header-bar');
      expect($('#course_header')).toHaveClass('neutral-header-bar');
      expect($('#course_header')).toHaveClass('bar-hover');
      expect($('.grading_task_section')).not.toHaveClass('program-header-bar');
      expect($('.grading_task_section')).toHaveClass('neutral-header-bar');
      expect($('.grading_task_section')).not.toHaveClass('bar-hover');
    });

    it('adds a class to style the left section header that is focused', function() {
      $('#section_header').removeClass('program-header-bar');
      $('#section_header').addClass('neutral-header-bar');
      $('#clicked_section').click();
      expect($('#section_header')).toHaveClass('program-header-bar');
      expect($('#section_header')).not.toHaveClass('netural-header-bar');
      expect($('#section_header')).not.toHaveClass('bar-hover');
    });
    
    it('adds toggles the classes on the right side section headers', function() {
      $('#section_1011').addClass('program-header-bar').
        removeClass('neutral-header-bar');
      $('#clicked_section').click();
      expect($('#section_1011')).not.toHaveClass('program-header-bar');
      expect($('#section_1011')).toHaveClass('neutral-header-bar');
      expect($('#section_1011')).toHaveClass('bar-hover');
      expect($('#section_666')).toHaveClass('program-header-bar');
      expect($('#section_666')).not.toHaveClass('netural-header-bar');
      expect($('#section_666')).not.toHaveClass('bar-hover');
    });
    
  });

  describe('When drilling into a section from the right hand side', function() {
    beforeEach(function() {
      appendSetFixtures('<div id="focus_indicator" data-js-focus=\'{"course": 123,"section": null}\'></div>');
      VHL.Dashboard.init();  
    });

    it('clears any styling on the course level header', function() {
      $('.grading_task_section').addClass('porgram-header-bar');
      $('.grading_task_section').removeClass('netural-header-bar bar-hover');
      $('#right_side_click').click();
      expect($('.grading_task_section')).toHaveClass('neutral-header-bar');
      expect($('.grading_task_section')).not.toHaveClass('bar-hover');
      expect($('.grading_task_section')).not.toHaveClass('program-header-bar');
    });
    
    it('Toggles the styling on the section headers', function() {
      $('#section_1011').addClass('program-header-bar').
        removeClass('neutral-header-bar bar-hover');
      $('#right_side_click').click();
      expect($('#section_1011')).not.toHaveClass('program-header-bar');
      expect($('#section_1011')).toHaveClass('neutral-header-bar');
      expect($('#section_1011')).toHaveClass('bar-hover');
      expect($('#section_666')).toHaveClass('program-header-bar');
      expect($('#section_666')).not.toHaveClass('netural-header-bar');
      expect($('#section_666')).not.toHaveClass('bar-hover');
    });
  });
  // TODO: FixTest: Skip it. sortable() is not working
  xdescribe('#sort_courses', function() {
    var update_callback, course_order_data;

    beforeEach(function() {
      appendSetFixtures('<div id="focus_indicator" data-js-focus=\'{"course": 123,"section": 456}\'></div>');
      spyOn($.fn, 'sortable').andCallFake(function(opts) {
        update_callback = opts.update;
      });
      spyOn($, 'ajax').andCallFake(function(opts) {
        course_order_data = opts.data;
      });
    });

    it('calls sortable on the courses for each school', function() {
      VHL.Dashboard.init();
      expect($.fn.sortable).toHaveBeenCalled();
    });

    it('posts to the server with the correct data upon sort update', function() {
      spyOn(VHL.Common, 'program_id').andReturn('79');
      VHL.Dashboard.init();
      update_callback();
      expect($.ajax).toHaveBeenCalled();
      expect(course_order_data).toEqual({
        course_order: "123,100",
        program_id: '79'
      });
    });

    it('sorts the course list in the focus', function() {
      VHL.Dashboard.init();
      update_callback();
      var order = $.map($('#focus_list > dl'), function(elm) {
        return $(elm).text();
      });
      expect(order).toEqual(["3", "4", "1", "2"]);
    });
  });
});


