/**
 * This class is for overlay feature where a transparent div is added
 * along with clickable transparent proxy hotspots at the place of
 * clickable/ hotspot elements and click action is simulated on those proxy hotspots.
 */
class OverlayBuilder {
  /**
   * Creates overlay element
   * @param {String} selectorClass css class to add on the overlay element
   * @return {HTMLElement} overlay element
   */
  static create(selectorClass) {
    const overlay = document.createElement('div');
    overlay.classList.add(
      'ns-music-v1', 'c-transparent-overlay', 'u-hidden', 'js-modal-a11y', selectorClass
    );
    overlay.tabIndex = 0;
    overlay.ariaLabel = '';
    return overlay;
  }

  /**
   * Creates and appends overlay in DOM if already not present
   * @param {String} selectorClass css class to add in overlay element
   * @return {HTMLElement} overlay element
   */
  static append(selectorClass) {
    let overlay = document.querySelector(`.${selectorClass}`);
    if (!overlay) {
      overlay = this.create(selectorClass);
      document.body.appendChild(overlay);
    }
    return overlay;
  }

  /**
   * Creates transparent proxy hotspot at similar location as provided hotspotElement
   * @param {HTMLElement} hotspotElement clickable element in the DOM to be simulated
   * @param {String} featureType
   * @param {String} ariaLabelText aria label text for proxy hotspot element
   * @return {HTMLElement} clickable transparent proxy hotspot element
   */
  static getProxyHotspot(hotspotElement, featureType, ariaLabelText) {
    const left = hotspotElement.getBoundingClientRect().left + window.scrollX;
    const top = hotspotElement.getBoundingClientRect().top + window.scrollY;
    const width = hotspotElement.offsetWidth;
    const height = hotspotElement.offsetHeight;

    const proxyHotspot = document.createElement('button');
    proxyHotspot.classList.add(
      'c-proxy-hotspot', 'c-no-button', 'js-proxy-hotspot'
    );
    proxyHotspot.ariaLabel = ariaLabelText || 'Selectable Area';
    proxyHotspot.style.width = `${width}px`;
    proxyHotspot.style.height = `${height}px`;
    proxyHotspot.style.top = `${top}px`;
    proxyHotspot.style.left = `${left}px`;
    if (hotspotElement.childElementCount > 0) {
      const hotspotDetails = hotspotElement.querySelector(':first-child').id;
      proxyHotspot.setAttribute('aria-describedby', hotspotDetails);
    }

    if (featureType === 'help-request') {
      proxyHotspot.id = this.getHelpReqProxyHotspotId(hotspotElement);
    } else {
      proxyHotspot.id = this.getNonHelpReqProxyHotspotId(hotspotElement);
    }

    return proxyHotspot;
  }

  /**
   * Get transparent proxy hotspot id for Help Request
   * @param {HTMLElement} hotspotElement - clickable element in the DOM to be simulated
   * @return {String} clickable transparent proxy hotspot element
   */
  static getHelpReqProxyHotspotId(hotspotElement) {
    const id = hotspotElement.firstElementChild?.id;
    if (id) return `overlay-${id}`;
  }

  /**
   * Get transparent proxy hotspot id for non help request cases.
   * @param {HTMLElement} hotspotElement - clickable element in the DOM to be simulated
   * @return {String} clickable transparent proxy hotspot element
   */
  static getNonHelpReqProxyHotspotId(hotspotElement) {
    if (hotspotElement.id) return `overlay-${hotspotElement.id}`;
  }

  /**
   * Adds transparent proxy hotspot
   * @param {HTMLElement} overlay overlay element
   * @param {HTMLElement} hotspotElement clickable element in the DOM to be simulated
   * @param {HTMLElement} featureType
   * @param {String} ariaLabelText aria label text for proxy hotspot element
   * @return {HTMLElement} clickable transparent proxy hotspot element
   */
  static addProxyHotspot(overlay, hotspotElement, featureType, ariaLabelText = null) {
    const proxyHotspot = this.getProxyHotspot(hotspotElement, featureType, ariaLabelText);
    if (overlay) {
      overlay.appendChild(proxyHotspot);
    }
    return proxyHotspot;
  }

  /**
   * Shows overlay and sets focus
   * @param {HTMLElement} overlay overlay element
   */
  static showOverlay(overlay) {
    overlay.classList.add('c-help-request-info-mode');
    overlay.classList.remove('u-hidden');
    document.body.classList.add('u-pos-rel');
    overlay.focus();
  }

  /**
   * Hides overlay
   * @param {HTMLElement} overlay overlay element
   */
  static hideOverlay(overlay) {
    overlay.classList.remove('c-help-request-info-mode');
    overlay.classList.add('u-hidden');
    document.body.classList.remove('u-pos-rel');
  }

  /**
   * Removes all transparent clickable proxy hotspot elements from overlay
   * @param {HTMLElement} overlay overlay element
   */
  static removeProxyHotspots(overlay) {
    if (overlay) {
      while (overlay.firstChild) {
        overlay.removeChild(overlay.firstChild);
      }
      overlay.classList.remove('c-help-request-info-mode');
      overlay.classList.add('u-hidden');
    }
    document.body.classList.remove('u-pos-rel');
  }

  /**
   * Adds accessibility in overlay element
   * @param {String} overlayClass css class as selector in overlay element
   * @return {HTMLElement} overlay element
   */
  static overlayAccessibility(overlayClass) {
    const overlay = document.querySelector(`.${overlayClass}`);
    const proxyHotspots = overlay.querySelectorAll('.js-proxy-hotspot');
    const proxyHotspotNum = proxyHotspots.length;

    proxyHotspots[0].classList.add(
      'js-modal-a11y__first-focus-element', 'js-modal-a11y__default-focus'
    );
    proxyHotspots[proxyHotspotNum - 1].classList.add(
      'js-modal-a11y__last-focus-element'
    );

    /* Bind Keydown on first focusable element to prevent the Shift+Tab key to go out of the overlay
    */
    proxyHotspots[0].addEventListener('keydown', (evt) => {
      if (evt.keyCode === 9 && evt.shiftKey) {
        proxyHotspots[proxyHotspotNum - 1].focus();
        evt.preventDefault();
      }
    });

    /**
    * Bind Keydown on last focusable element to prevent the Tab key to go out of the overlay
    */
    proxyHotspots[proxyHotspotNum - 1].addEventListener('keydown', (evt) => {
      if (evt.keyCode === 9 && !evt.shiftKey) {
        proxyHotspots[0].focus();
        evt.preventDefault();
      }
    });

    return overlay;
  }
}

export default OverlayBuilder;
