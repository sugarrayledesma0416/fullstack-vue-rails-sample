/*
  JavaScript manifest for music-v1-only layouts
  
  Used by the responsive layout (done by setting a flag when
  including layouts/common_header.js). Used by, e.g., Gradebook.
  
  Includes only core JS, some libraries for shared functionality, 
  and more up-to-date versions of jQuery and jQueryUI.
*/

//= require jquery-3.2.1/jquery
//= require jquery_ujs
//= require jquery-3.2.1/jquery-ui
//= require jquery-accessible-dropdown-menus
//= require underscore-min
//= require jquery-ui-timepicker-addon
//= require jquery.tools.min
//= require jquery.vhl-disable-link-toggle

//= require angular
//= require angular-route
//= require angular-placeholder

//= require application-common
//= require music/application
//= require hicks/application
//= require vhl_templater

//= require masthead
//= require focus

// jwerty must be placed after application-common
//= require jwerty

// Add the stats modules
//= require diller/application.js
//= require carlin_dispatch

// pubnub-chat related files
//= require chat/lib/cw-combine.min.js
//= require chat/lib/pubnub.min.js
//= require chat/lib/opentok.min.js
//= require chat/lib/av-checks-combine.min.js
//= require chat_bootstrap.js

// Stream Audio Uploader
//= require sha256
//= require stream_audio_uploader

//= require merge_webpack_exports

// Add no javascript code to this file directly!
