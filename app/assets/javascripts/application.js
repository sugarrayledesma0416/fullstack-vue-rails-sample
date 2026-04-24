/*
  Main JavaScript manifest
  
  Used in almost all layouts. The responsive layout (layouts/responsive.html.erb)
  uses application-music-v1.js instead (by setting a flag when including layouts/common_header.js)
*/

//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jquery-accessible-dropdown-menus
//= require parseHTML
//= require underscore-min

//= require jquery-ui-timepicker-addon
//= require jquery.tools.min
//= require jquery.vhl-disable-link-toggle

// angular stuff
//= require angular
//= require angular-route
//= require angular-placeholder

//= require application-common

// storage and jwerty must be placed after application-common
//= require jwerty
//= require storage

// use the hicks audio / video and music libraries everywhere
//= require music/application
//= require hicks/application

//= require vhl_templater

// Add the stats modules
//= require diller/application.js
//= require carlin_dispatch

// Recorder shim to allow basic Web Audio API usage
//= require recorder/shim

// Stream Audio Uploader
//= require sha256
//= require stream_audio_uploader

// Activity js files
//= require activity_submission.js

// pubnub-chat related files
//= require chat/lib/cw-combine.min.js
//= require chat/lib/pubnub.min.js
//= require chat/lib/opentok.min.js
//= require chat/lib/video_access_checker.js
//= require chat/lib/av-checks-combine.min.js
//= require chat_bootstrap.js

//= require vhl_templater

//= require merge_webpack_exports

// Add no javascript code to this file directly!
