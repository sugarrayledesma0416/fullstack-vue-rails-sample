//= require study_plans/study_plan.js

describe('VHL.StudyPlan', function() {
  var hiddenClass = 'u-hidden';
  var uncompletedConceptClass = 'c-icon--ok-dim';
  var completedConceptClass = 'c-icon--ok';
  var studyPlan;
  var completeClass = 'is-complete';
  var incompleteClass = 'is-incomplete';
  var conceptContainer;
  VHL.Shapes = { init: function() { return true; } };
  window.popup_activity_maestro2_size = function() { return true; };


  beforeEach(function() {
    loadFixtures('study_plan.html');
    studyPlan = VHL.StudyPlan.integrateWithView();
  });

  describe('when loading', function() {
    beforeEach(function() {
      conceptContainer = $('[data-concept="18"]');
    });

    describe('when concepts needs readings', function() {
      it('displays recommendation links', function() {
        expect(conceptContainer.find('[data-user-reading-path]')).not.toHaveClass(hiddenClass);
      });

      it('displays an empty progress bar', function() {
        var chartContainer = conceptContainer.find('[data-concept-chart]');
        expect(chartContainer).toHaveClass(incompleteClass);
        expect(chartContainer.data('pointer')).toEqual('whole');
      });

      it('displays an uncompleted check mark', function() {
        expect(conceptContainer.find('[data-concept-check-mark]')).toHaveClass(uncompletedConceptClass);
      });
    });

    describe('when concepts does not need any readings', function() {
      beforeEach(function() {
        conceptContainer = $('[data-concept="18.1"]');
      });

      it('does not display recommendation links', function() {
        expect(conceptContainer.find('[data-user-reading-path]')).toHaveClass(hiddenClass);
      });

      it('displays a filled progress bar', function() {
        var chartContainer = conceptContainer.find('[data-concept-chart]');
        var readingsContainer = conceptContainer.find('[data-concept-readings]');
        expect(chartContainer).toHaveClass(completeClass);
        expect(chartContainer.data('pointer')).toEqual('start');
        expect(readingsContainer).toHaveClass(completeClass);
        expect(readingsContainer.data('pointer')).toEqual('end');
      });

      it('displays a completed check mark', function() {
        expect(conceptContainer.find('[data-concept-check-mark]')).toHaveClass(completedConceptClass);
      });
    });
  });

  describe('when clicking a recommendation', function() {
    beforeEach(function() {
      conceptContainer = $('[data-concept="18"]');
    });

    it('sets the recommendation as read', function() {
      var readingLink = conceptContainer.find('[data-user-reading-path]:first');
      readingLink.click();
      expect(readingLink).toHaveClass('is-complete');
      expect(readingLink).not.toHaveClass('is-incomplete');
    });


    describe('when there are recommendations left to browse', function() {
      it('displays an uncompleted check mark', function() {
        var readingLink = conceptContainer.find('[data-user-reading-path]:first');
        readingLink.click();
        expect(conceptContainer.find('[data-concept-check-mark]')).toHaveClass(uncompletedConceptClass);
      });
    });

    xdescribe('when all ecommendations for the concept have been read', function() {
      it('displays a completed check mark', function() {
        var readingLink = conceptContainer.find('[data-user-reading-path]:first');
        conceptContainer.find('[data-user-reading-path]').addClass('is-complete');
        readingLink.click();
        expect(conceptContainer.find('[data-concept-check-mark]')).toHaveClass(completedConceptClass);
      });

      it('displays a filled progress bar', function() {
        var chartContainer = conceptContainer.find('[data-concept-chart]');
        var readingsContainer = conceptContainer.find('[data-concept-readings]');
        expect(chartContainer).toHaveClass(completeClass);
        expect(chartContainer.data('pointer')).toEqual('start');
        expect(readingsContainer).toHaveClass(completeClass);
        expect(readingsContainer.data('pointer')).toEqual('end');
      });
    });
  });
});
