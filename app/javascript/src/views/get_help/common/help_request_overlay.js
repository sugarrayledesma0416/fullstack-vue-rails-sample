import OverlayBuilder from 'shared/accessible_hotspots/overlay_builder';

/**
 * Class required to perform some overlay operation specific to Help Request
 */
class HelpRequestOverlay extends OverlayBuilder {
  /**
  * Initialise Help Request Overlay.
  * @param {Object} controllerRef
  * @param {Object} getHelpHelper
  * @param {HTMLElement} hotspotElement
  * @param {Boolean} isExistingParent
  */
  static init() {
    this.overlayClass = 'js-transparent-hr-overlay';
    this.overlay = this.append(this.overlayClass);
    this.showOverlay(this.overlay);
  }

  /**
  * Select Hotspot Element
  * @param {Object} controllerRef
  * @param {Object} getHelpHelper
  * @param {HTMLElement} hotspotElm
  */
  static selectHotspotElm(controllerRef, getHelpHelper, hotspotElm) {
    hotspotElm.classList.add('js-selected-element');
    getHelpHelper.helpableDivClickCallback({
      data: { controllerRef: controllerRef, element: hotspotElm },
    });
  }

  /**
  * Create Proxy Hotspot over overlay
  * @param {Object} controllerRef
  * @param {Object} getHelpHelper
  * @param {HTMLElement} hotspotElm
  * @param {Boolean} isExistingParent
  */
  static createProxyHotspot(controllerRef, getHelpHelper, hotspotElm, isExistingParent = false) {
    let proxyHotspot;
    if (isExistingParent) {
      proxyHotspot = this.addProxyHotspot(this.overlay, hotspotElm.parentNode, 'help-request');
    } else {
      proxyHotspot = this.addProxyHotspot(this.overlay, hotspotElm.parentNode, 'help-request');
    }
    proxyHotspot.addEventListener('click', () => {
      this.selectHotspotElm(controllerRef, getHelpHelper, hotspotElm);
    });

    proxyHotspot.addEventListener('keypress', (evt) => {
      if (evt.keyCode === 32) {
        this.selectHotspotElm(controllerRef, getHelpHelper, hotspotElm);
      }
    });
  }

  /**
  * Create Cancel Proxy button over overlay
  * @param {Object} scope
  * @param {HTMLElement} hotspotElement Actual Cancel Button.
  */
  static createCancelBtnProxy(scope, hotspotElement) {
    const proxyHotspot = this.addProxyHotspot(
      this.overlay, hotspotElement, 'help-request', 'Cancel Request'
    );
    proxyHotspot.addEventListener('click', () => {
      scope.cancelRequest();
    });

    proxyHotspot.addEventListener('keypress', (evt) => {
      if (evt.keyCode === 13 || evt.keyCode === 32) {
        scope.cancelRequest();
      }
    });
  }

  /**
  * Add Accessibility for all elements of overlay.
  * @param {Object} scope
  */
  static addAccessibility(scope) {
    const overlay = this.overlayAccessibility(this.overlayClass);
    overlay.addEventListener('keyup', (evt) => {
      if (evt.keyCode === 27) {
        scope.cancelRequest();
      }
    });
    overlay.querySelector('.js-modal-a11y__first-focus-element').focus();
  }
}
export default HelpRequestOverlay;
