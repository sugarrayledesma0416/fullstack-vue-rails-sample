var VHL = VHL || {};

VHL.VocabWords.Factories.factory('PopupService', function ($compile) {
  var popupService = {};

  /**
    Create a confirm dialog box.
    @param {string} title -The title of the confirm box
    @param {object} confirmMsg -The message text to be displayed
    @param {string} confirmBtnText - The button text for the confirm action button
    @param {string} confirmAction - The name of the function to be executed on confirmation
    @param {string} scope - scope passed in for angular compiling.
 */

    popupService.confirm = function (title, confirmMsg, confirmBtnText, confirmAction, scope) {
    var confirmBtn = $('<button class="confirm-btn" ng-click=' + confirmAction + '>' + confirmBtnText + '</button>');
    var cancelBtn = $("<button class='cancel-btn'>Cancel</button>");
    var popupElement = $('<div>' + confirmMsg + '<div id="standard_cancel_action_links"></div></div>');
    popupElement.find('#standard_cancel_action_links').append(confirmBtn);
    popupElement.find('#standard_cancel_action_links').append(cancelBtn);
    var popup_options = {
      title: title,
      resizable: false,
      modal: true
    };

    this.compilePopup(popupElement, scope, popup_options);

  }

  /**
   * Create a dialog box from content existing on page.
   * @param {string} id - The id attribute of element to display as a dialog box.
   * @param {object} popup_options - object of options to pass to jquery ui dialog.
   * @param {string} scope - scope passed in for angular compiling.
   */

  popupService.dialog = function(id, closeBtnText, popup_options, scope ) {
    var popupElement = $('#'+id);
    var close_btn = $('.close-btn').text(closeBtnText);
    var dialog_title = "Practice | " + scope.mode.shown_header +  " | " + scope.mode.hidden_header;
    popupElement.removeClass('target_base');
    popupElement.removeClass('base_target');
    popupElement.removeClass('def_target');
    popupElement.removeClass('def_base_target');
    popupElement.removeClass('target_def');

    popupElement.addClass(scope.mode.css_class);
    popupElement.append(close_btn);
    popupElement.dialog({ modal: true});
    popupElement.dialog("option", "minWidth", 852); //hard coded until design integration of vocab tool
    popupElement.dialog("option", "resizable", false); //TODO don't hardcode this
    popupElement.dialog( "option", "position", { my: "center", at: "center", of: window } );//TODO don't hardcode this
    popupElement.dialog("option", "title", dialog_title);
    popupElement.removeClass('hidden_helper');
    close_btn.bind("click", function() {
     popupElement.dialog('close');
    });

    //this.compilePopup(popupElement, scope, popup_options);
  }

  popupService.new_dialog = function() {

  }


  popupService.compilePopup = function(popup, scope, popup_options) {
    $compile(popup)(scope);
    popup.dialog(popup_options);
    popup.find('.cancel-btn, .confirm-btn').on("click", function() {
      popup.dialog("close"); //should look for a better way to handle closing dialogs
    });
  }

return popupService;
});
