//= require activity_shell

describe("VHL.ActivityShell", function() {
  it("has a namespace", function() {
    expect(VHL.ActivityShell).toBeDefined();
  });

  describe("When the page initializes", function() {

    describe("the reference tools dropdown", function() {
      beforeEach(function() {
        setFixtures('<select id="program_ref_link"><option value=""></option><option value="http://vistas4e.vhlcentral.com/home/dictionary.php">Online Mini Dictionary</option><option value="http://www.vistasonline.com/media/shockwave/dictionary.htm">VHL Online Dictionary</option><option value="http://www.vistasonline.com/media/shockwave/GrammarTerms.htm">Grammar Reference</option><option value="http://www.vistasonline.com/media/shockwave/VerbWheel.htm">Verb Wheel</option></select>');
      });

      it("does not display the first empty option", function() {
        VHL.ActivityShell.init();
        expect($('#program_ref_link').find('option:first')).not.toBeVisible();
      });
    });

    describe("the sample answer toggle", function() {
      beforeEach(function() {
        setFixtures('<div data-js-link="sample_answer_toggle">View sample answer</div><div class="sample_answer_container">Sample Answer</div>');
      });

      it("should bind a click event to the sample answer toggle", function() {
        VHL.ActivityShell.init();
        expect($('[data-js-link="sample_answer_toggle"]')).toHandle("click");
      });

      it('should hide or show the sample answer container when clicked', function() {
        var toggle_link = $('[data-js-link="sample_answer_toggle"]');
        $('.sample_answer_container').removeClass('hidden_helper');
        VHL.ActivityShell.init();
        toggle_link.trigger("click");
        expect($('.sample_answer_container')).toHaveClass('hidden_helper');
        toggle_link.trigger("click");
        expect($('.sample_answer_container')).not.toHaveClass('hidden_helper');
        $('.sample_answer_container').removeClass('hidden_helper');
      });

      it('should change the sample answer toggle text when clicked', function() {
        var toggle_link = $('[data-js-link="sample_answer_toggle"]');
        VHL.ActivityShell.init();
        toggle_link.trigger("click");
        expect(toggle_link).toHaveText('View sample answer');
        toggle_link.trigger("click");
        expect(toggle_link).not.toHaveClass('Hide sample answer');
      });
    });

    describe("when the activity has a vText link", function() {
      beforeEach(function() {
        setFixtures('<div class="vtext_pages" id="strand_page_number"><a href="/vtext/panorama4e/ebook/pan4e_new.html?rid=0&amp;page=2" data-link-type="vtext">2-5</a></div>')
      });

      xit("binds the link to the parent container", function() {
        VHL.ActivityShell.init();
        expect($('#strand_page_number')).toHandle("click");
      });
    });

    describe("when the activity has select boxes", function() {
      beforeEach(function() {
        loadFixtures('activity_shell.html')
      });

      //This spec passes in the browser and fails in the console because in the console
      //the this.offsetWidth values are different
      it("sets them all to have the same width as the widest one", function() {
        VHL.ActivityShell.init();
        var longer_width = $('#question_01_1').outerWidth()
        expect($('#question_01_1').outerWidth()).toEqual(longer_width);
        expect($('#question_02_1').outerWidth()).toEqual(longer_width);
      });
    });

    describe("when there are notifications", function() {
      beforeEach(function() {
        setFixtures('<div id="show_notifications_link">Show Notifications</div><div id="notification_listing" style="display: none">Notifications</div>')
      });

      it("shows or hides the notifications window when clicked", function() {
        var link = $('#show_notifications_link');
        var container = $('#notification_listing');
        VHL.ActivityShell.init();
        expect(container).toHaveCss({ display: 'none'});
        link.trigger('click');
        expect(container).toHaveCss({ display: 'block'});
        link.trigger('click');
        expect(container).toHaveCss({ display: 'none'});
      });
    });

    // Fails when running the whole set
    xdescribe('when non gradable activity has been submitted', function () {
      var activity_attempts_div;

      beforeEach(function() {
        loadFixtures('activity_shell.html');
        // timecop initialization
        Timecop.install();
        Timecop.freeze(new Date(2014, 02, 07, 5, 15));
        activity_attempts_div = $('#activity_attempts');
        $(document).trigger('non_gradable_submitted');
      });

      afterEach(function() {
        // To uninstall Timecop and reinstate the native Date constructor
        Timecop.uninstall();
      });

      describe('when non_gradable_submitted has been triggered', function () {
        it('updates activity_attempts area with proper message', function () {
          expect(activity_attempts_div).toContainHtml("Completed on <br> Friday, 7th 5:15 AM");
        });
      });

    });

  });
});
