VHL = VHL || {};

VHL.AccentBarComponentWrapper = class AccentBarComponentWrapper {
  constructor() {
    const accentBarEnabled = document.querySelector('meta[name="VHL.program_accent_bar_enabled"]')
    ?.content === 'true' || false;
    if (accentBarEnabled) {
      this.accentBarComponent = new VHL.AccentBarComponent();
      this.initializeAccentBarFeatureOnActivityPage();
      this.deactivateAccentBarOnHelpRequestClick();
    }
  }

  initializeAccentBarFeatureOnActivityPage() {
    //TODO: We should change the id selector by js class in inputBoxes to improve the implementations.
    let inputBoxes = $('#activity_body, .js-accent_bar_container').find('input[type=text], textarea:not([data-js-ckeditor])');
    inputBoxes.each((index, inputBoxEle) => {
      if (this.accentBarComponent && !inputBoxEle.classList.contains('datepicker')) this.accentBarComponent.register(inputBoxEle);
    });
  }

  deactivateAccentBarOnHelpRequestClick() {
    const helpRequestLink = document.querySelector('.js-help-request-mode');
    if (helpRequestLink) {
      if (this.accentBarComponent) {
        helpRequestLink.addEventListener('click', () => {
          this.accentBarComponent.deactivateAll();
        });
      }
    }
  }
}

$(document).ready(function () {
  let accentBarComponentWrapper = new VHL.AccentBarComponentWrapper();
});
