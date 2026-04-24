//= require restangular.min

var VHL = VHL || {};

VHL.GetHelp = angular.module('get_help_app', ['restangular']);

// Manually Initilize Angular because of Multiple Applications.
/*angular.element(document).ready(function() {
  angular.bootstrap($('body'), ['get_help_app']);
});*/

/**
 * I commented out this manual initialization because it was causing a redundancy with the static inclusion of ng-app and
 * ng-controller for pages with help requests. This caused things like ng-click to be executed twice.
 *
 * If we end up needing this dyanmic inclusion, here is a possible design pattern for future implementation:
 * http://docs.angularjs.org/api/angular.bootstrap
 *
 * var $self = $(elm);
 * $self.attr('ng-controller','inlineEditorCtrl');
 * angular.bootstrap($self);
 *
 * The idea is to add an ng-controller parameter to the element we're passing to angular.bootstrap()
 *
 * Matt
 */
