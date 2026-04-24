var VHL = VHL || {};

VHL.ActivityFeedback = class ActivityFeedback {
  
  init() {
    $('.js-activity-main-form').on('ajax:success', (response, data) => this.updateForm(response, data));
    $('.js-activity-main-form').on('ajax:error', () => this.showErrorDialog);
  };

  updateForm(response, data) {
    document.querySelector('.js-activity-diagnostic-feedback').innerHTML = data.feedback;
    document.querySelector('.js-activity-diagnostic-preview').classList.add('u-hidden');
    this.showDonutReview(data.donut_results);
  }
  
  showErrorDialog() {
    $('.js-modal-ajax-alert').vhlModal('open');
  }

  showDonutReview(data) {
    let donutTemplate = document.querySelector('.js-template-diagnostic-review').innerHTML;
    let diagnosticContainer = document.querySelector('.js-activity-diagnostic-donut-chart');
    let colorsByTheme = [];
    const bodyStyles = window.getComputedStyle(document.body);

    diagnosticContainer.innerHTML = VHL.Templater.get(data, donutTemplate);

    if(document.querySelector('.js-jr-program').getAttribute('data-program') === 'true') {
      colorsByTheme = [bodyStyles.getPropertyValue('--ui-success-color'),
                        bodyStyles.getPropertyValue('--ui-neutral-light')];
    } else {
      colorsByTheme = [bodyStyles.getPropertyValue('--palette-green'),
                        bodyStyles.getPropertyValue('--palette-gray-c')];
    }

    let options = Object.freeze({
      width: 160,
      innerSize: '75%',
      colors: colorsByTheme,
      size: '100%'
    });

    let donutContainer = document.getElementById('results-chart-container');
    new VHL.Charts.DonutChart(donutContainer, data, options).render();
    const event = new CustomEvent('donut_loaded', {detail: data});
    document.querySelector('.js-activity-diagnostic-donut-chart').dispatchEvent(event);
  }
}

window.addEventListener('DOMContentLoaded', () => {
  new VHL.ActivityFeedback().init();
});
