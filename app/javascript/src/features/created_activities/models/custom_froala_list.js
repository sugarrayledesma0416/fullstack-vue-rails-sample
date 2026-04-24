import FroalaEditor from 'froala-editor';

/**
 * Contains static methods to configure the Froala List plugin.
 */
export default class CustomFroalaList {
  /**
   * Configures a toolbar Unordered List option to be used in the
   * IGC direction line editor.
   */
  static setDirectionLineUL() {
    /* eslint-disable new-cap */
    FroalaEditor.RegisterCommand('formatDirectionLineUL', {
      title: 'Unordered List',
      type: 'button',
      hasOptions: () => true,
      options: {
        disc: 'Disc',
        circle: 'Circle',
        square: 'Square',
        default: 'Non visible',
      },
      refresh: function(e) {
        this.lists.refresh(e, 'UL');
      },
      callback: function(e, t) {
        this.lists.format('UL', (t === undefined ? 'disc' : t));
      },
      plugin: 'lists',
    });
    FroalaEditor.DefineIcon(
      'formatDirectionLineUL',
      {
        NAME: 'list-ul',
        SVG_KEY: 'unorderedList',
      }
    );
    /* eslint-enable new-cap */
  }
}
