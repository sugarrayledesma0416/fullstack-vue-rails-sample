/**
 * Stores a collection of icons used by the Intranav.  Icons can be of any type,
 * but the collection must contain a full set of icons.  This helps ensure that
 * various themes all have equivalent icon collections.
 */
export class IconCollection {
  /**
   * @template T
   * @param {T} sayIt
   * @param {T} match
   * @param {T} listenRepeat
   * @param {T} diagnostics
   * @param {T} videoTutorial
   *
   * @constructor
   */
  constructor(
    sayIt,
    match,
    listenRepeat,
    diagnostics,
    videoTutorial
  ) {
    this.sayIt = this._validateIcon(sayIt);
    this.match = this._validateIcon(match);
    this.listenRepeat = this._validateIcon(listenRepeat);
    this.diagnostics = this._validateIcon(diagnostics);
    this.videoTutorial = this._validateIcon(videoTutorial);
  }

  /**
   * Validates a given icon and throws an exception if validation fails.
   *
   * @param {T} icon - The icon to validate.
   * @return {T} The valid icon.
   * @private
   */
  _validateIcon(icon) {
    const iconType = typeof icon;
    if (iconType === undefined || iconType === null) {
      throw new TypeError('Icon cannot be a nullish value.');
    }
    return icon;
  }
}

