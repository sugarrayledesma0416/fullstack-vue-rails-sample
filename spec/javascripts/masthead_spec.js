//= require masthead


describe('VHL.Masthead', function() {
  describe('Subnavigation', function() {
    var first_subnav, second_subnav;

    beforeEach(function() {
      loadFixtures('subnavigation.html');
      VHL.Masthead.init();

      var subnavs = $('.with_subnav');
      first_subnav = $(subnavs[0]);
      second_subnav = $(subnavs[1]);
    });

    it('shows the subnav when the mouse enters the subnav container', function() {
      first_subnav.mouseenter();
      expect(first_subnav.children('.subnav').hasClass('invisible')).toBeFalsy();
    });

    it('hides the subnav when the mouse leaves the subnav container', function() {
      first_subnav.mouseenter();
      first_subnav.mouseleave();
      expect(first_subnav.children('.subnav').hasClass('invisible')).toBeTruthy();
    });

    it('shows the subnav when a click event is triggered on the span', function() {
      first_subnav.children('span').click();
      expect(first_subnav.children('.subnav').hasClass('invisible')).toBeFalsy();
    });

    it('hides the subnav when an anchor is clicked', function() {
      first_subnav.mouseenter();
      first_subnav.find('a').first().click();
      expect(first_subnav.children('.subnav').hasClass('invisible')).toBeTruthy();
    });

    it('hides all other subnavs when a subnav is clicked', function() {
      first_subnav.click();
      second_subnav.click();
      expect(first_subnav.children('.subnav').hasClass('invisible')).toBeTruthy();
    });

    it('hides all subnavs when a click event is triggered outside of a subnav', function() {
      first_subnav.click();
      $('html').click();
      expect(first_subnav.children('.subnav').hasClass('invisible')).toBeTruthy();
    });
  });
});
