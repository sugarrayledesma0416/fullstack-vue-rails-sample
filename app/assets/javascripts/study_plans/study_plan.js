var VHL = VHL || {};

VHL.StudyPlan = {};

VHL.StudyPlan.integrateWithView = function() {
  function setupConcept(container, needsReading, conceptComplete) {
    var complete = (!needsReading || conceptComplete);
    var statusClass = complete ? 'is-complete' : 'is-incomplete';
    var chartShape = complete ? 'start' : 'whole';
    var readingsShape = complete ? 'end' : 'none';
    var pointerShapeClass = complete ? 'js-pointer' : '';
    var readingsPointerClass = complete ? 'c-block-pointer' : 'c-no-pointer';
    var checkMarkClass = complete ? 'c-icon--ok' : 'c-icon--ok-dim';

    container.find('[data-concept-title]').addClass(statusClass);
    container.find('[data-concept-progress]').addClass(statusClass);

    // handle chart shape stuff
    container.find('[data-concept-chart]')
      .addClass(statusClass)
      .attr('data-pointer', chartShape);

    container.find('[data-concept-reading-list]').addClass(statusClass);
    // handle readings shape
    container.find('[data-concept-readings]')
      .addClass(statusClass)
      .addClass(pointerShapeClass)
      .addClass(readingsPointerClass)
      .attr('data-pointer', readingsShape);

    container.find('[data-concept-check-mark]').addClass(checkMarkClass);
  }

  function updateConcept(conceptContainer) {
    var readings = conceptContainer.find('[data-user-reading-path]');
    var complete = true;
    _.each(readings, function(reading) {
      complete = complete && $(reading).hasClass('is-complete');
    });
    if (complete) {
      setupConcept(conceptContainer, false, complete);
      conceptContainer.find('[data-concept-check-mark]').removeClass('c-icon--ok-dim');
      VHL.Shapes.refresh();
    }
  }

  function bindReadingLinksActions() {
    $('[data-user-reading-path]').click(function() {
      var link = $(this);
      var userReadingUrl = link.data('user-reading-path');
      var notViewed = !link.hasClass('is-complete');
      if (notViewed) {
        $.ajax({
          url: userReadingUrl,
          type: 'PUT',
        })
        .success(function() {
          link.removeClass('is-incomplete').addClass('is-complete');
          updateConcept(link.parents('tbody'));
        });
      }
    });
  }

  function initializeConcepts() {
    _.each($('[data-concept]'), function(conceptContainer) {
      var container = $(conceptContainer);
      var needsReading = container.data('needs-reading');
      var conceptComplete = container.data('complete');
      setupConcept(container, needsReading, conceptComplete);

      // hide readings if user doesn't need to read them
      if (!needsReading) {
        container.find('[data-user-reading-path]').addClass('u-hidden');
      }
    });
  }

  initializeConcepts();
  bindReadingLinksActions();
  VHL.Shapes.init();
};

$(document).ready(VHL.StudyPlan.integrateWithView);
