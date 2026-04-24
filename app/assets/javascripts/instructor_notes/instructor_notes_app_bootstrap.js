//= require_self
//= require recorder/application
//= require ../angular/angular-animate.min.js
//= require_tree ../instructor_notes
//= require maestro_activity_engine/swfobject
//= require maestro_activity_engine/vhl_ng/bootstrap
//= require maestro_activity_engine/vre

var VHL = VHL || {};

/**
 * Instructor Notes
 * This is an angular app that has been through some hard times, and some things
 * it does are anti-patterns for angular.
 * @namespace VHL.InstructorNotes
 */
VHL.InstructorNotes = angular.module('instructor_notes_app', ['ngAnimate', 'instructor_notes_app.controllers', 'restangular']);

VHL.InstructorNotes.Controllers = angular.module('instructor_notes_app.controllers', ['vhl.directives']);

VHL.InstructorNotes.config(['RestangularProvider', function (RestangularProvider) {
  RestangularProvider.setDefaultHeaders({
    "X-CSRF-Token": $("meta[name='csrf-token']").attr("content")
  });
}]);

