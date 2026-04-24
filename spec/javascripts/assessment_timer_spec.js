//= require assessment_timer


describe("VHL.AssessmentTimer", function () {
  var assessment_timer, timer_display, timer_container;

  beforeEach(function() {
    loadFixtures('assessment_timer.html');
    assessment_timer = new VHL.AssessmentTimer();
    timer_display = $('.timer-display');
    timer_container = $('#assessment_timer');
  });

  describe("#start", function () {
    it("sets up the sync interval, display interval, sumbit timeout", function() {
      jasmine.Clock.useMock();
      var spy_interval = spyOn(window, 'setInterval');
      var spy_timeout = spyOn(window, 'setTimeout');
      assessment_timer.start({
        polling_interval: 10,
        time_left_seconds: 100,
        original_time_seconds: 100,
        sync_url: '/attempt/10/sync_time',
        timer_elm: $("#assessment_timer")
      });
      expect(spy_interval).toHaveBeenCalled();
      expect(spy_timeout).toHaveBeenCalled();
    });

    it("sets all the instance variables", function() {
      jasmine.Clock.useMock();
      assessment_timer.start({
        polling_interval: 10,
        time_left_seconds: 100,
        sync_url: '/attempt/10/sync_time',
        timer_elm: $("#assessment_timer"),
        radial_timer: 'Radial Timer Object'
      });
      expect(assessment_timer.polling_interval).toEqual(10);
      expect(assessment_timer.sync_url).toEqual('/attempt/10/sync_time');
      expect(assessment_timer.time_left_seconds).toEqual(100);
      expect(assessment_timer.timer_display_hr.length).toBe(1);
      expect(assessment_timer.timer_display_min.length).toEqual(1);
      expect(assessment_timer.timer_display_sec.length).toEqual(1);
      expect(assessment_timer.radial_timer).toEqual('Radial Timer Object');
    });
  });

  describe("#display_updater", function() {
    it("update the display appropriately", function() {

      jasmine.Clock.useMock();
      assessment_timer.start({
        polling_interval: 10,
        time_left_seconds: 100,
        original_time_seconds: 100,
        sync_url: '/attempt/10/sync_time',
        timer_elm: $("#assessment_timer"),
        radial_timer: {
          animate: jasmine.createSpy(),
          timer_style: jasmine.createSpy()
        }
      });
      expect($("#assessment_timer .hr").html()).toEqual('00');
      expect($("#assessment_timer .min").html()).toEqual('01');
      expect($("#assessment_timer .sec").html()).toEqual('40');
      jasmine.Clock.tick(1000);
      expect($("#assessment_timer .hr").html()).toEqual('00');
      expect($("#assessment_timer .min").html()).toEqual('01');
      expect($("#assessment_timer .sec").html()).toEqual('39');
      expect(assessment_timer.radial_timer.timer_style).toHaveBeenCalledWith(99000);
      expect(assessment_timer.radial_timer.animate).toHaveBeenCalledWith(99000);
    });

    it("decrements time left by one second", function(){
      jasmine.Clock.useMock();
      assessment_timer.start({
        polling_interval: 10,
        time_left_seconds: 100,
        original_time_limit: 100,
        sync_url: '/attempt/10/sync_time',
        timer_elm: $("#assessment_timer")
      });
      jasmine.Clock.tick(1000 * 1);
      expect(assessment_timer.time_left_seconds).toEqual(99);
    });
  });

  describe('#init_timer_display', function() {
    it("minimizes the timer when timer is clicked", function() {
      assessment_timer.init_timer_display();
      timer_container.click();
      expect(timer_container).toHandle('click');
      expect(timer_container).toHaveClass('minimized');
      expect(timer_display).toBeHidden();
    });
  });

  describe('#two_minute_warning', function() {
    describe('When the time is 2:00', function (){
      it('Should open the timer', function () {
        assessment_timer.is_open = false;
        timer_container.addClass('minimized');
        assessment_timer.two_minute_warning(1000 * 60 * 2);
        expect(timer_container).not.toHaveClass('minimized');
      });
    });

    describe('When the time is > 2:00', function (){
      it('Should leave the time alone', function () {
        assessment_timer.is_open = false;
        timer_container.addClass('minimized');
        assessment_timer.two_minute_warning(1000 * 60 * 3);
        expect(timer_container).toHaveClass('minimized');
      });
    });

    describe('When the time is < 2:00', function (){
      it('Should leave the timer alone if it has already been opened', function () {
        assessment_timer.is_open = true;
        timer_container.addClass('minimized');
        assessment_timer.two_minute_warning(1000 * 60);
        expect(timer_container).toHaveClass('minimized');
      });
    });

    describe('If something went wrong and the timer didn\'t pop open at 2:00', function() {
      it('Pops open', function() {
        assessment_timer.is_open = false;
        timer_container.addClass('minimized');
        assessment_timer.two_minute_warning(1000 * 60 * 1);
        expect(timer_container).not.toHaveClass('minimized');
      });
    });
  });

  describe('VHL.RadialTimer', function() {
    var radial_timer;

    beforeEach(function() {
      radial_timer = new VHL.RadialTimer(180);
    });

    describe('animate', function() {
      it('generates a blue arc when the time left is above two minutes', function() {
        spyOn(radial_timer, 'generate_arc');
        radial_timer.animate(3 * 60 * 1000);
        expect(radial_timer.generate_arc).toHaveBeenCalledWith(jasmine.any(Number), 'blue');
      });

      it('generates a red arc when the time left is above two minutes', function() {
        spyOn(radial_timer, 'generate_arc');
        radial_timer.animate(1 * 60 * 1000);
        expect(radial_timer.generate_arc).toHaveBeenCalledWith(jasmine.any(Number), 'red');
      });
    });

    describe('#generate_arc', function() {
      it('sets the background image of the timer animation', function() {
        spyOn($.fn, 'css');
        radial_timer.generate_arc(-100, 'red');
        expect($.fn.css).toHaveBeenCalledWith('background-image', jasmine.any(String));
      });
    });

    describe('#timer_style', function() {
      it('hides the hour elm and divider when time left is less than an hour', function() {
        radial_timer.timer_style(45 * 60 * 1000);
        expect($('.hr')).toBeHidden();
        expect($('.hr-divider')).toBeHidden();
      });

      it('enlarges the clock when time left is less than an hour', function() {
        radial_timer.timer_style(45 * 60 * 1000);
        expect($('.countdown')).toHaveClass('large-clock');
      });

      it('changes the color of the numbers when time left is less than two minutes', function() {
        radial_timer.timer_style(1 * 60 * 1000);
        expect($('.countdown')).toHaveClass('ending-countdown-color');
      });
    });
  });
});

