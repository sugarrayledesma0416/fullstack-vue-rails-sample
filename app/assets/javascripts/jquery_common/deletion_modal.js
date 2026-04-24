/* global VHL */

VHL.jQueryCommon = VHL.jQueryCommon || {};

/* DeletionDialog:
 * how it works? pass options:
 * opts:
 * bindTo: css class to bind click event.
 * objectType: what's going to be deleted?
 * [objectType].title: modal title for the element to be deleted.
 * [objectType].content: modal message for the element to be deleted.
 *
 * example:
 * opts = {
 *  bindTo: '.js-remove-things',
 *  foo: {
 *    title: Remove Foo?,
 *    content: You'll remove foo, you know?
 *  },
 *  bar: {
 *    title: Destroy Bar?,
 *    content: Really? Ok, it's up to you...
 *  }
 * }
 *
 * in the HTML, define the elements (a, div, etc) that will trigger the dialog
 * confirmation, example:
 * <a href="#"
 *    data-delete-url="some_delete_path"
 *    data-object-type="foo"
 *    class="js-remove-things">Remove</a>
 *
 * You need to define data-delete-url, data-object-type and add the js class
 * that DeletionDialog will use to bind click event.
 *
 * The idea is that you can use the same modal dialog to destroy different
 * kind of objects within the same page, in this example, foo and bar objects
 */

VHL.jQueryCommon.DeletionDialog = (function() {
  var dialog = function(opts) {
    var deletionModal = $('.js-deletion-modal');
    function setModalContent(objectType, deleteUrl) {
      deletionModal.find('.js-modal-content').text(opts[objectType].content);
      deletionModal.find('.js-dialog-heading').text(opts[objectType].title);
      deletionModal.find('.js-deletion-form').prop('action', deleteUrl);
      deletionModal.vhlModal('open');
    }

    $(opts.bindTo).click(function() {
      var deleteUrl = $(this).data('delete-url');
      var objectType = $(this).data('object-type');
      setModalContent(objectType, deleteUrl);
    });

  };

  return dialog;
}());
