//= require moment-with-langs.min

var VHL = VHL || {};

VHL.ActivityShell = (function() {
  function displayGradeDetails() {
    $('#activity_details').dialog({
      resizable: false,
      width: 350,
      dialogClass: 'activity-details',
      buttons: [{ text: 'close', click: function() {
        $( this ).dialog( 'close' );
      }}]
    });
  }

  function getOSVersion() {
    /* global window */
    var agent = window.navigator.userAgent;
    var start = agent.indexOf('OS');

    if ((agent.indexOf('iPhone') > -1 || agent.indexOf('iPad') > -1) && start > -1) {
      return window.Number(agent.substr(start + 3, 3).replace('_', '.'));
    } else {
      return 0;
    }
  }

  /**
   *  This method now ONLY adjusts the Smart Book iframe height.
   */
  function setActivityHeight() {
    if ($('#santillana_book_iframe').length) {
      const viewHeight = $(window).height();
      const activityFooterHeight = $('.activities .js-activity-footer-wrap').outerHeight(true);
      const activityHeaderHeight = $('#santillana_book_iframe').offset().top;
      /* iframeAddExtraHeight add an extra height for the iframe viewport that not afect the footer and header visibility. */
      const iframeAddExtraHeight = 30;
      const iframeHeight = viewHeight - activityHeaderHeight - activityFooterHeight + iframeAddExtraHeight;
      $('#santillana_book_iframe').css('height', `${iframeHeight}px`);
    }
  }

  function openToolWindow(link) {
    const url = link.href;
    const windowName = $(link).text().replace(/ /gi, '');
    let winWidth = 1000, winHeight = 700, windowOpts;

    if (url === '') {
      return false;
    }

    // Verbwheel
    if (url === 'http://www.vistasonline.com/media/shockwave/VerbWheel.htm') {
      winWidth = 560;
      winHeight = 516;

    // Grammar Terms
    } else if (url === 'http://www.vistasonline.com/media/shockwave/GrammarTerms.htm') {
      winWidth = 710;
      winHeight = 450;

    // VHL Dictionary
    } else if (url === 'http://www.vistasonline.com/media/shockwave/dictionary.htm') {
      winWidth = 730;
      winHeight = 425;

    // German Dictionary
    } else if (url === 'http://www.wordreference.com/ende/') {
      winWidth = 730;
      winHeight = 425;

    // Oxford Dictionary
    } else if (url === 'http://vistas4e.vhlcentral.com/home/dictionary.php') {
      winWidth = 525;
      winHeight = 450;
    }

    windowOpts = `directories=no,location=no,resizable=yes,status=yes,scrollbars=yes,toolbar=no,
width=${winWidth},height=${winHeight}`;

    // Let the default link action populate the window URL:
    window.open('', windowName, windowOpts).focus();
    link.target = windowName;
    return true;
  }

  function setReferenceLinkActions() {
    $('.js-ref-tool-link').on('click', (evt) => {
      return openToolWindow(evt.currentTarget);
    });
  }

  function setSampleAnswerToggle() {
    // Show/Hide Sample Answer
    $('[data-js-link="sample_answer_toggle"]').click(function(event) {
      var $sampleContainer = $(this).siblings('.sample_answer_container');

      if ($sampleContainer.hasClass('hidden_helper')) {
        $sampleContainer.removeClass('hidden_helper');
        $(this).text('Hide sample answer');
      } else {
        $sampleContainer.addClass('hidden_helper');
        $(this).text('View sample answer');
      }
      event.preventDefault();
    });
  }

  function setIpadScroll() {
    function iPadScroll() {
      document.querySelector('.js-activity-footer-wrap').style.top =
        (window.pageYOffset + window.innerHeight - 74) + 'px';
    }

    // if Ipad version < 5, change how Activity Footer works.
    if (navigator.platform === 'iPad' && getOSVersion() <= '5.0') {
      window.addEventListener('touchstart', iPadScroll, false);
      window.onscroll = function() {
        iPadScroll();
      };
    }
  }

  function makeVTextLink() {
    var vTextLink = $('[data-link-type]="vtext"');
    if (vTextLink.length > 0) {
      $('#vtext_reference').click(function(clickEvent) {
        // don't cause infinite loop
        var isClickPropagatedFromChild = (clickEvent.target === vTextLink[0]);

        var disabledAttr = vTextLink.attr('disabled');
        // this can return "undefined" in some browsers and "false" in others
        var isEnabled = (typeof disabledAttr === 'undefined' || disabledAttr === false);

        if (!isClickPropagatedFromChild && isEnabled) {
          vTextLink.click();
        } else {
          // Trigger the helpable container when the vText link is disabled.
          const helpable = $(this).parents('.helpable');
          if (helpable.length > 0) {
            helpable.click();
          } else {
            // If the helpable container is not found, use default link behavior.
            return;
          }
        }
        return false;
      }).hover(function() {
        $('.open_vtext').css('text-decoration', 'underline');
      }, function() {
        $('.open_vtext').css('text-decoration', 'none');
      });
    }
  }

  function maxSelectWidth() {
    // Set selectboxes to have the same width as the widest one.
    var maxWidth = 0;
    $('#activity_body').find('select').each(function() {
      if ($(this).outerWidth() > maxWidth) {
        maxWidth = $(this).outerWidth();
      }
    });
    $('#activity_body').find('select').css('width', maxWidth);
  }

  function toggleNotificationsDisplay() {
    // Show/Hide Notifications
    $('#show_notifications_link').click(function() {
      $('#notification_listing').toggle();
    });
  }

  function toggleActivityDetails() {
    // Show/Hide Activity Details on user click
    $('.js-toggle-activity-details-button').click(function () {
      $('.js-toggle-activity-details').toggleClass('u-dis-none');
      if ($(this).attr('aria-expanded') == 'false') {
        $(this).attr('aria-expanded', 'true'); // Set state for Screen Readers
        $(this).val('Hide Details');
      } else {
        $(this).attr('aria-expanded', 'false');
        $(this).val('Show Details');
      }
    });
  }

  function toggleActivityInfoModal() {
    $('.js-toggle-activity-info-modal').on('click', () => {
      $('.js-activity-info-modal').vhlModal('open');
    })
  }

  function toggleMappedStandardsModal() {
    $('.js-toggle-mapped-standards-modal').on('click', () => {
      $('.js-mapped-standards-modal').vhlModal('open');
    })
  }

  function helpPopovers() {
    var howPopover = $('.how-to-use-details');
    var howToUseLink = $('.how-to-use');
    var objectivesPopover = $('.objectives-details');
    var objectivesLink = $('.objectives');

    howPopover.dialog({autoOpen: false,
                        position: { my: 'right top',
                                    at: 'right top+30',
                                    of: howToUseLink
                                  }
                       });

    howPopover.find('.close').click(function() {
      howPopover.dialog('close');
    });

    howToUseLink.click(function(ev) {
      howPopover.dialog('open');
      objectivesPopover.dialog('close');
      ev.stopPropagation();
    });

    objectivesPopover.dialog({autoOpen: false,
                               position: { my: 'right top',
                                           at: 'right top+30',
                                           of: objectivesLink
                                         }
                              });

    objectivesPopover.find('.close').click(function() {
      objectivesPopover.dialog('close');
    });

    objectivesLink.click(function(ev) {
      objectivesPopover.dialog('open');
      howPopover.dialog('close');
      ev.stopPropagation();
    });
  }

  function checkSmartbookIframeLoaded(iframe, callback) {
    var iframeDoc = iframe.contentDocument;

    if (iframeDoc && iframeDoc.readyState === 'complete') {
      // The iframe is loaded
      callback(iframe);
    } else {
      // The iframe is not loaded. Start a timer to check the status later.
      window.setTimeout(function() {
        checkSmartbookIframeLoaded(iframe, callback);
      }, 500);
    }
  }

  // Monitor the iframe and call the callback when the iframe is loaded.
  function onSmartbookIframeLoaded(iframe, callback) {
    // Tying further execution to the iframe onload event ensures that
    // we don't try to interact with the smartbook JavaScript app until
    // all the iframe content has finished loading.
    iframe.onload = function() {
      callback(iframe);
    }

    // And since we do not always receive the onload event, start a timer to
    // check the iframe status on a regular interval until it is loaded.
    window.setTimeout(function() {
      checkSmartbookIframeLoaded(iframe, callback);
    }, 500);
  }

  function setUpSmartbook() {
    var santillanaIframe = document.getElementById('santillana_book_iframe');
    // This code runs for all activities, so we only want to proceed if
    // there's santillana content.
    if (santillanaIframe) {
      // Other JS may have set this same value but we need to be sure it's
      // set, otherwise JavaScript in the m3 DOM isn't allowed to talk to
      // the iFrame contents.
      document.domain = 'vhlcentral.com';

      onSmartbookIframeLoaded(santillanaIframe, setUpSmartbookIframeLoaded);
    }
  }

  function setUpSmartbookIframeLoaded(iframe) {
    // We have 3 different possibilities:
    // #1. The santillanaIframe holds a smartbook. In that case,
    //     iframe.contentWindow.app is defined.
    // #2. The santillanaIframe holds a Galeria smartbook. In this case
    //     the html that's loaded in the santillanaIframe iframe itself
    //     contains an iframe (id #container). Use the app from this
    //     container iframe.
    // #3. The santillanaIframe holds a static book. In that case, app
    //     will be undefined.

    // If this call succeeds, the santillanaIframe holds a smartbook:
    // there is nothing more to do.
    if (setUpSmartbookIframe(iframe)) { return; }

    // If we get past the guard clause, check whether the iframe holds a
    // Galeria smartbook.
    var containerIframe = iframe.contentWindow.document.getElementById('container');

    // If it does hold a Galeria smartbook, run setUpSmartbookApp either
    //
    //   1. as an onload event handler, or
    //   2. after we detect by polling that the content has loaded
    //
    // (whichever happens first).
    if (containerIframe) {
      onSmartbookIframeLoaded(containerIframe, setUpSmartbookIframe);
    }
  }

  function setUpSmartbookIframe(iframe) {
    // If app is defined, the iframe holds a smartbook.
    var app = iframe.contentWindow.app;
    if (app) {
      setUpSmartbookApp(app);

      // when we call this method directly for the santillanaIframe
      // and the santillanaIframe holds a smartbook,
      // we can use this return status to skip looking for the iframe
      // in the Galeria smartbook.
      return true;
    }
  };

  /**
   * Returns a function that will ensure fn will be called only once
   * @param {function} fn - The function to be called only once
   * @returns a function
   *
   * @example
   * my_function = once(function(arg_1, arg_2) {
   *   console.log('This method will be called only once!');
   * });
   *
   * my_function('foo', 'bar'); // prints "This method will be called only once!"
   * my_function('foo', 'bar'); // do nothing.
   */
  const once = fn => (...args) => {
    if (!fn) return;
    fn(...args);
    fn = null;
  };

  // Declare this method using the once helper to be sure it is called only once.
  setUpSmartbookApp = once(function(app) {
    setUpSmartbookAudio(app);
    setUpSmartbookLinks(app);
  });

  function setUpSmartbookAudio(app) {
    var authToken = $("meta[name='VHL.lossless_auth_token']").attr('content');
    var sectionId = $("meta[name='VHL.section_guid']").attr('content') || '0';
    var baseEndpoint = VHL.multimediaConfig.smartbook.recording_endpoint;
    var endpoint = baseEndpoint + '/' + sectionId + '/' + authToken + '/';

    setUpSmartbookAudioEndpoints(app, endpoint);
  }

  function setUpSmartbookAudioEndpoints(app, endpoint) {
    // If app.eventBus or app.dat aren't defined, then
    // we may be dealing with a different version of the smartbook app
    // that isn't compatible with our manipulation.
    if (app && app.eventBus && app.dat) {
      // Binding to this event from the app ensures that all the recording
      // sub-activity components have been initialized with their default
      // properties. If we try and set the overrides too early, later
      // execution could replace our values with the original values.

      app.eventBus.on('app:ready', function() {
        var recordingActivities = app.dat.getCompsByName('qSpeakingOption');

        // Override the upload endpoint.
        _.each(recordingActivities, function(activity) {
          var parser;
          var pathArray;
          if (activity.properties) {
            console.log('Setting uploadLink to "' + endpoint + '" for activity ' + activity.id);
            activity.properties.uploadLink = endpoint;
          }
          // And for playback, replace token in stored amazonLink with
          // current token.
          model = app.compController.getModelById(activity.id);
          oldLink = model.attributes.amazonLink;
          if (oldLink.length) {
            // Use a document 'a' element to parse the original uri.
            // This avoid having to do string manipulations to strip out
            // the scheme and hostname.
            parser = document.createElement('a');
            parser.href = oldLink;
            pathArray = parser.pathname.split('/');
            // We want to replace the first 3 elements of the current path.
            // The current path looks like this: 'smartbook/section/token/xxx/yyy/zzz.wav'
            // We first split the path, then discard the first 4 elements.
            // parser.pathname.split('/') = ['', 'smartbook', 'section', 'token', 'xxx', 'yyy', 'zzz.wav']
            newLink = endpoint + pathArray.slice(4).join('/');
            console.log('Setting playback link to "' + newLink + '" in activity ' + activity.id);
            model.attributes.amazonLink = newLink;
          }
        });
      });
    }
  }

  function setUpSmartbookLinks(app) {
    // If app.eventBus or app.dat aren't defined, then
    // we may be dealing with a different version of the smartbook app
    // that isn't compatible with our manipulation.
    if (app && app.eventBus && app.dat) {
      app.eventBus.on("pageContent.inserted", function() {
        // #1. The santillanaIframe holds a smartbook.
        preventSmartbookLinksDefaultBehavior($('#santillana_book_iframe'));
        // #2. The santillanaIframe holds a Galeria smartbook. In this case
        //     the html that's loaded in the santillanaIframe iframe itself
        //     contains an iframe (id #container).
        var containerIframe = $('#santillana_book_iframe').contents().find('iframe#container');
        preventSmartbookLinksDefaultBehavior(containerIframe);
      });
    }
  }

  function preventSmartbookLinksDefaultBehavior(iframe) {
    var links = iframe.contents().find('a[href="#"]');
    links.click(function(event) {
      // Prevent default which causes the top-level page to move to a different
      // vertical scroll position and makes the activity header disappear.
      event.preventDefault();
    });
  }

  function openNotEnrolledSubmissionWarningModal() {
    let elt = document.querySelector('.js-modal-not-enrolled-submission-warning');
    if (elt) {
      $(elt).vhlModal('open');
    }
  }

  function init() {
    setReferenceLinkActions();
    setSampleAnswerToggle();
    VHL.ActivityShell.setActivityHeight();
    makeVTextLink();
    maxSelectWidth();
    toggleNotificationsDisplay();
    toggleActivityDetails();
    toggleActivityInfoModal();
    toggleMappedStandardsModal();
    helpPopovers();
    $('.what-counts').click(displayGradeDetails);
    setUpSmartbook();
    openNotEnrolledSubmissionWarningModal();
  }

  return {
    init: init,
    setActivityHeight: setActivityHeight,
    setIpadScroll: setIpadScroll
  };
})();

$(document).ready(function() {
  VHL.ActivityShell.init();
});

$(window).resize(function() {
  VHL.ActivityShell.setActivityHeight();
});

window.onload = function() {
  VHL.ActivityShell.setIpadScroll();
};

$(document).on('non_gradable_submitted', function() {
  var updateTimeString = moment().format('dddd, Do h:mm A');
  var htmlMessage = 'Completed on <br /> ' + updateTimeString;
  $('#activity_attempts').html(htmlMessage);
});
