/*
  Shared JS code.

  Used to be embedded in application.js.
  Now required by both application.js and application-music-v1.js.
*/


//top level namespace for all VHL javascript
var VHL = {};

if (!window.console) console = {};
console.log = console.log || function(){};

$(document).ajaxSend(function(e, xhr, options) {
  var token = $("meta[name='csrf-token']").attr("content");
  xhr.setRequestHeader("X-CSRF-Token", token);
});

/* http://stackoverflow.com/questions/946534/insert-text-into-textarea-with-jquery/946556 */
jQuery.fn.extend({
  insertAtCaret: function(myValue){
    return this.each(function(i) {
      if (document.selection) {
        //For browsers like Internet Explorer
        this.focus();
        var sel = document.selection.createRange();
        sel.text = myValue;
        this.focus();
      }
      else if (this.selectionStart || this.selectionStart == '0') {
        //For browsers like Firefox and Webkit based
        var startPos = this.selectionStart;
        var endPos = this.selectionEnd;
        var scrollTop = this.scrollTop;
        this.value = this.value.substring(0, startPos) + myValue + this.value.substring(endPos,this.value.length);
        this.focus();
        this.selectionStart = startPos + myValue.length;
        this.selectionEnd = startPos + myValue.length;
        this.scrollTop = scrollTop;
      } else {
        this.value += myValue;
        this.focus();
      }
    });
  }
});


VHL.Common = (function(){
  var trackError = $("meta[name='VHL.enable_js_error_logging']").attr('content') === 'true';
  let shouldPreventWarnings = false;
  function createJSErrorLog(errorReport) {
    if (!trackError) return;

    $.ajax({
      type: 'POST',
      url: '/javascript_errors_controller',
      data: errorReport
    });
  }

  function parse_query_string(){
    var params = {};
    var qs = window.location.search.replace('?', '')
    var pairs = qs.split('&')
    $.each(pairs, function(i, v){
      var pair = v.split('=')
      var key = unescape(pair[0])
      var value = unescape(pair[1])
      params[key] = value
    })
    return params
  }

  function metaTagContent(name) {
    const tagElm = document.querySelector(`meta[name="${name}"]`);
    return tagElm.getAttribute('content');
  }

  /**
   * Set flag to ensure to log user out after timeout by preventing further warnings.
   */
  function preventWarningsAfterTimeout() {
    shouldPreventWarnings = true;
  }

  /**
   * Return whether to prevent further warnings.
   * This will be used by 'beforeunload' event handlers at various pages
   * to suppress another warning dialog (eg. unsaved data warnings or
   * confirmation dialogs) after timeout.
   * @return {boolean}
   */
  function shouldPreventWarningsAfterTimeout() {
    return shouldPreventWarnings;
  }

  function program_id() {
    return VHL.Common.metaTagContent('VHL.program_id');
  }

  function unescape_xml_entities(string_with_entities) {
    var unescape = string_with_entities.replace(/&apos;/g, "\'");
    unescape = unescape.replace(/&quot;/g, "\"");
    unescape = unescape.replace(/&amp;/g, "\&");
    unescape = unescape.replace(/&lt;/g, "\<");
    unescape = unescape.replace(/&gt;/g, "\>");
    return unescape;
  }

  function init() {
    VHL.Common.disable_link_hover();
    VHL.Common.unassignable_dialog();
    VHL.Common.unassignable_student_dialog();
    VHL.Common.bind_prevent_default();

    if (document.forms[0]) {
      first_form = document.forms[0];
      if (!$(first_form).is('no_initial_cursor')){
        if (!$(first_form).find(':input').filter(':visible:first') == undefined) $(first_form).find(':input').filter(':visible:first').not('.has_datepicker').focus();
      }
    }

    setTimeout("$(\"#flash_notice\").fadeOut('slow');", 30000);
  }

  function bind_prevent_default() {
    $("a.prevent-default").click(function(event) {
      event.preventDefault();
    });
  }

  function build_ajax_url(suffix) {
    var location = window.location;
    var port = '';

    // remove trailing slash from pathname and leading slash from suffix, so we don't get double slashes
    var clean_pathname = location.pathname.replace(/\/$/, '');
    var clean_suffix = suffix.replace(/^\//, '');
    if(location.port != ''){
      port = ':' + location.port;
    }
    return location.protocol + '//' + location.hostname + port + clean_pathname + '/' + clean_suffix;
  }

  function disable_link_hover() {
    // Control the Disabled Hover
    $('.disable_link_function').hover(function(){
       $(this).find('.disabled_hover_info').removeClass('hidden_helper');
    }, function() {
       $(this).find('.disabled_hover_info').addClass('hidden_helper');
    });
  }

  /*
    gear_click_event could be called multiple times, so, we need to execute it
    ONCE in order to avoid double binds in gear elements.
  */
  VHL.gear_click_event_bound = false;

  function gear_click_event(params) {
    /*
    Explanation of Usage:

    The gear_click_event function is to be used for areas such as the Instructor Dashboard, where the intended
    functionality is having a small gear that opens into a dropdown menu.

    Please observe the following formatting:

    <div class="course_gear">             - Sets the location of the gear itself.
      <a href="#" class="gear">Gear</a>   - The Clickable Gear Image.
      <div class="gear_menu">             - This is the ordinarily hidden container that opens when the gear is clicked.
        <ul>
          <li class="gear_option"></li>   - Each link or line of information inside the gear menu should be wrapped in an li like this.
        </ul>
      </div>
    </div>

    That's all there is to it!

    */
    if (VHL.gear_click_event_bound) {
      return;
    }

    var _cursor_is_inside = function() { _cursor_is_inside = true;}    // We use the "cursor_is_inside" bit to make it so clicking outside of the gear menu will close it.
    var _cursor_is_outside = function() { _cursor_is_inside = false;}

    $('a.gear').hover( _cursor_is_inside, _cursor_is_outside);
    $('a.gear').click(function(event) // Clicking the Gear Icon does the following
    {
      event.stopPropagation();

      if(params != null && params.callback != undefined) {
        params.callback($(this));
      }

      /* Actual Javascript to make it work */
      $(this).toggleClass('active');
      $(this).siblings('.gear_menu').addClass('open');

      $(this).siblings('.gear_menu').toggle(10, function()
      {
        $('html').on("click touchend", function()
        {
            $('.gear_menu.open').hide();
            $('.gear_menu').removeClass('open');
            $('a.gear').removeClass('active');
        });
      });

      $('.gear_option span').on("click touchend", function(event) {
        event.stopPropagation();
      })

      $('.gear_option a').on("click touchend", function(event) {
        event.stopPropagation();
      })
    return false;
    });
    VHL.gear_click_event_bound = true;
  }

  function get_value_if_exists(selector){
    element = $(selector);
    if (element.length == 0) {
      return '';
    }
    return element.val();
  }

  function initialize_datepicker(){
    if ($('.has_datepicker').length == 0) {
      return false;
    }
    var datepicker_min_date     = get_value_if_exists('#datepicker_min_date');
    var datepicker_max_date     = get_value_if_exists('#datepicker_max_date');
    var datepicker_default_date = get_value_if_exists('#datepicker_default_date');

    $('.has_datepicker').datepicker({
      dateFormat: 'mm/dd/yy',
      minDate: datepicker_min_date,
      maxDate: datepicker_max_date,
      defaultDate: datepicker_default_date,
      showOn: "focus",
      buttonImage: "/images/calendar.gif",
      buttonImageOnly: true,
      buttonText: 'Set due date',
      gotoCurrent: true
    });
  }

  function jquery_dialog_setup(element, params) {
    $('#modal_box').dialog({
      title: $(element).attr('title'),
      minHeight: params.min_height,
      modal: true,
      resizable: false,
      width: params.width,
      open: function (e, ui) {
        $('#modal_box').append("<div id='modal_spinner' style='position:absolute;top:15%;left:35%;'><img alt='page loading' src='/images/loading_32.gif'/></div>");
      },
      close: function (e, ui) {
        $('#tabs').tabs();
        $('#delete_link').remove();
        $('#modal_box').html('');
        $('.ui-dialog-buttonpane').remove();
      }
    }).load($(element).attr('href') + ' form', function() {
      $('#tabs').tabs();

      $('[data-js-link="close_modal"]').on("click", function(e) {
        e.preventDefault();
        $('#modal_box').dialog( "close" );
      });

      // Remove trailing zero on Edit Category Modampl.
      $('#category_weighting_percent').on("change", function() {
        var input = $(this);
        var weightValue = input.val();
        weightValue = weightValue.replace(/^0+/, '');
        input.val(weightValue);
      });

      if ($("#category_accept_late_work_true").is(':checked')) {
        $('#late_work_penalties').removeClass('hidden_helper');
      }

      $('#modal_spinner').remove();
      $form = $(this).find('form');
      $form.find(':text:first').not('.has_datepicker').focus();
      $btn = $form.find(':submit');
      var txt = $btn.val();
      var confirmation = $btn.attr('confirmation');
      $btn.remove();
      var buttons = {};
      var dlg = $(this);
      buttons[txt] = function() {
        if (typeof confirmation != 'undefined') {
          if (!confirm(confirmation)) {
            dlg.dialog('close');
            return false;
          }
        }
        $.ajax({
          type: $form.attr('method'),
          url: $form.attr('action'),
          data: $form.serialize(),
          dataType: params.data_type || 'script',
          beforeSend: function(xhr, status) {
            $('#modal_spinner').remove();
            $('#modal_box').append("<div id='modal_spinner' style='display:none;position:absolute;top:15%;left:35%;'><img alt='page loading' src='/images/loading_32.gif'/></div>");
            $('#modal_spinner').show();
          },
          success: function(xhr, status) {
            $('#modal_spinner').hide();
            dlg.dialog('close');
            if (typeof(params.success_callback) === 'function') {
              params.success_callback(xhr);
            }

          },
          error: function(data) {
            $('#modal_spinner').hide();
            if (params.data_type === 'html') {
              $('#jquery_modal_error_status').remove();
              $form.prepend('<div id="jquery_modal_error_status" class="ui-state-error ui-corner-all">There was an error processing your request. Please check that all fields are valid and try again.</div>')
            } else {
              errors = $.parseJSON(data.responseText);
              if (errors) {
                VHL.Common.set_error_class_for_fields(errors.fields_with_errors);
                error_div = $form.find('#jquery_modal_error_status');
                if (error_div.length === 0) {
                  $form.prepend('<div id="jquery_modal_error_status" class="ui-state-error ui-corner-all">' + errors.errors_message_block + '</div>');
                } else {
                  error_div.html(errors.errors_message_block);
                }
              }
            }
          }
        });
      };
      $(this).dialog('option','buttons', buttons);

      var emptybutton = $('.ui-button-text');
      if (emptybutton.text() == "undefined") {
        emptybutton.parent().hide();
      }

      var emptybutton = $('.ui-button-text-only');
      if (emptybutton.text() == "undefined") {
        emptybutton.parent().hide();
      }

      VHL.Common.initialize_datepicker();
      VHL.Common.move_jquery_modal_delete_link_into_button_pane();
      if (typeof prepare_disabled_element_explanations == 'function') {
        prepare_disabled_element_explanations();
      }
    });
  }

  function move_jquery_modal_delete_link_into_button_pane() {
    var delete_link_div = $('#delete_link');
    if (delete_link_div.length == 0) {
      return false;
    }

    delete_link_div.detach();
    delete_link_div.appendTo('.ui-dialog-buttonpane');
  }

  function prep_common_jquery_modal(params) {  //{ min_height:value, width:value, show_spinner:value }
    $('a.jquery_modal').unbind('click').bind('click', function() {
      jquery_dialog_setup(this, params);
      return false;
    });
  }

  //remove diacritics implementation taken from http://stackoverflow.com/questions/3939266/javascript-function-to-remove-diacritics
  function remove_diacritics(word){
    var default_diacritics_map = [
      {'base':'A', 'letters':/[\u0041\u24B6\uFF21\u00C0\u00C1\u00C2\u1EA6\u1EA4\u1EAA\u1EA8\u00C3\u0100\u0102\u1EB0\u1EAE\u1EB4\u1EB2\u0226\u01E0\u00C4\u01DE\u1EA2\u00C5\u01FA\u01CD\u0200\u0202\u1EA0\u1EAC\u1EB6\u1E00\u0104\u023A\u2C6F]/g},
      {'base':'AA','letters':/[\uA732]/g},
      {'base':'AE','letters':/[\u00C6\u01FC\u01E2]/g},
      {'base':'AO','letters':/[\uA734]/g},
      {'base':'AU','letters':/[\uA736]/g},
      {'base':'AV','letters':/[\uA738\uA73A]/g},
      {'base':'AY','letters':/[\uA73C]/g},
      {'base':'B', 'letters':/[\u0042\u24B7\uFF22\u1E02\u1E04\u1E06\u0243\u0182\u0181]/g},
      {'base':'C', 'letters':/[\u0043\u24B8\uFF23\u0106\u0108\u010A\u010C\u00C7\u1E08\u0187\u023B\uA73E]/g},
      {'base':'D', 'letters':/[\u0044\u24B9\uFF24\u1E0A\u010E\u1E0C\u1E10\u1E12\u1E0E\u0110\u018B\u018A\u0189\uA779]/g},
      {'base':'DZ','letters':/[\u01F1\u01C4]/g},
      {'base':'Dz','letters':/[\u01F2\u01C5]/g},
      {'base':'E', 'letters':/[\u0045\u24BA\uFF25\u00C8\u00C9\u00CA\u1EC0\u1EBE\u1EC4\u1EC2\u1EBC\u0112\u1E14\u1E16\u0114\u0116\u00CB\u1EBA\u011A\u0204\u0206\u1EB8\u1EC6\u0228\u1E1C\u0118\u1E18\u1E1A\u0190\u018E]/g},
      {'base':'F', 'letters':/[\u0046\u24BB\uFF26\u1E1E\u0191\uA77B]/g},
      {'base':'G', 'letters':/[\u0047\u24BC\uFF27\u01F4\u011C\u1E20\u011E\u0120\u01E6\u0122\u01E4\u0193\uA7A0\uA77D\uA77E]/g},
      {'base':'H', 'letters':/[\u0048\u24BD\uFF28\u0124\u1E22\u1E26\u021E\u1E24\u1E28\u1E2A\u0126\u2C67\u2C75\uA78D]/g},
      {'base':'I', 'letters':/[\u0049\u24BE\uFF29\u00CC\u00CD\u00CE\u0128\u012A\u012C\u0130\u00CF\u1E2E\u1EC8\u01CF\u0208\u020A\u1ECA\u012E\u1E2C\u0197]/g},
      {'base':'J', 'letters':/[\u004A\u24BF\uFF2A\u0134\u0248]/g},
      {'base':'K', 'letters':/[\u004B\u24C0\uFF2B\u1E30\u01E8\u1E32\u0136\u1E34\u0198\u2C69\uA740\uA742\uA744\uA7A2]/g},
      {'base':'L', 'letters':/[\u004C\u24C1\uFF2C\u013F\u0139\u013D\u1E36\u1E38\u013B\u1E3C\u1E3A\u0141\u023D\u2C62\u2C60\uA748\uA746\uA780]/g},
      {'base':'LJ','letters':/[\u01C7]/g},
      {'base':'Lj','letters':/[\u01C8]/g},
      {'base':'M', 'letters':/[\u004D\u24C2\uFF2D\u1E3E\u1E40\u1E42\u2C6E\u019C]/g},
      {'base':'N', 'letters':/[\u004E\u24C3\uFF2E\u01F8\u0143\u00D1\u1E44\u0147\u1E46\u0145\u1E4A\u1E48\u0220\u019D\uA790\uA7A4]/g},
      {'base':'NJ','letters':/[\u01CA]/g},
      {'base':'Nj','letters':/[\u01CB]/g},
      {'base':'O', 'letters':/[\u004F\u24C4\uFF2F\u00D2\u00D3\u00D4\u1ED2\u1ED0\u1ED6\u1ED4\u00D5\u1E4C\u022C\u1E4E\u014C\u1E50\u1E52\u014E\u022E\u0230\u00D6\u022A\u1ECE\u0150\u01D1\u020C\u020E\u01A0\u1EDC\u1EDA\u1EE0\u1EDE\u1EE2\u1ECC\u1ED8\u01EA\u01EC\u00D8\u01FE\u0186\u019F\uA74A\uA74C]/g},
      {'base':'OI','letters':/[\u01A2]/g},
      {'base':'OO','letters':/[\uA74E]/g},
      {'base':'OU','letters':/[\u0222]/g},
      {'base':'P', 'letters':/[\u0050\u24C5\uFF30\u1E54\u1E56\u01A4\u2C63\uA750\uA752\uA754]/g},
      {'base':'Q', 'letters':/[\u0051\u24C6\uFF31\uA756\uA758\u024A]/g},
      {'base':'R', 'letters':/[\u0052\u24C7\uFF32\u0154\u1E58\u0158\u0210\u0212\u1E5A\u1E5C\u0156\u1E5E\u024C\u2C64\uA75A\uA7A6\uA782]/g},
      {'base':'S', 'letters':/[\u0053\u24C8\uFF33\u1E9E\u015A\u1E64\u015C\u1E60\u0160\u1E66\u1E62\u1E68\u0218\u015E\u2C7E\uA7A8\uA784]/g},
      {'base':'T', 'letters':/[\u0054\u24C9\uFF34\u1E6A\u0164\u1E6C\u021A\u0162\u1E70\u1E6E\u0166\u01AC\u01AE\u023E\uA786]/g},
      {'base':'TZ','letters':/[\uA728]/g},
      {'base':'U', 'letters':/[\u0055\u24CA\uFF35\u00D9\u00DA\u00DB\u0168\u1E78\u016A\u1E7A\u016C\u00DC\u01DB\u01D7\u01D5\u01D9\u1EE6\u016E\u0170\u01D3\u0214\u0216\u01AF\u1EEA\u1EE8\u1EEE\u1EEC\u1EF0\u1EE4\u1E72\u0172\u1E76\u1E74\u0244]/g},
      {'base':'V', 'letters':/[\u0056\u24CB\uFF36\u1E7C\u1E7E\u01B2\uA75E\u0245]/g},
      {'base':'VY','letters':/[\uA760]/g},
      {'base':'W', 'letters':/[\u0057\u24CC\uFF37\u1E80\u1E82\u0174\u1E86\u1E84\u1E88\u2C72]/g},
      {'base':'X', 'letters':/[\u0058\u24CD\uFF38\u1E8A\u1E8C]/g},
      {'base':'Y', 'letters':/[\u0059\u24CE\uFF39\u1EF2\u00DD\u0176\u1EF8\u0232\u1E8E\u0178\u1EF6\u1EF4\u01B3\u024E\u1EFE]/g},
      {'base':'Z', 'letters':/[\u005A\u24CF\uFF3A\u0179\u1E90\u017B\u017D\u1E92\u1E94\u01B5\u0224\u2C7F\u2C6B\uA762]/g},
      {'base':'a', 'letters':/[\u0061\u24D0\uFF41\u1E9A\u00E0\u00E1\u00E2\u1EA7\u1EA5\u1EAB\u1EA9\u00E3\u0101\u0103\u1EB1\u1EAF\u1EB5\u1EB3\u0227\u01E1\u00E4\u01DF\u1EA3\u00E5\u01FB\u01CE\u0201\u0203\u1EA1\u1EAD\u1EB7\u1E01\u0105\u2C65\u0250]/g},
      {'base':'aa','letters':/[\uA733]/g},
      {'base':'ae','letters':/[\u00E6\u01FD\u01E3]/g},
      {'base':'ao','letters':/[\uA735]/g},
      {'base':'au','letters':/[\uA737]/g},
      {'base':'av','letters':/[\uA739\uA73B]/g},
      {'base':'ay','letters':/[\uA73D]/g},
      {'base':'b', 'letters':/[\u0062\u24D1\uFF42\u1E03\u1E05\u1E07\u0180\u0183\u0253]/g},
      {'base':'c', 'letters':/[\u0063\u24D2\uFF43\u0107\u0109\u010B\u010D\u00E7\u1E09\u0188\u023C\uA73F\u2184]/g},
      {'base':'d', 'letters':/[\u0064\u24D3\uFF44\u1E0B\u010F\u1E0D\u1E11\u1E13\u1E0F\u0111\u018C\u0256\u0257\uA77A]/g},
      {'base':'dz','letters':/[\u01F3\u01C6]/g},
      {'base':'e', 'letters':/[\u0065\u24D4\uFF45\u00E8\u00E9\u00EA\u1EC1\u1EBF\u1EC5\u1EC3\u1EBD\u0113\u1E15\u1E17\u0115\u0117\u00EB\u1EBB\u011B\u0205\u0207\u1EB9\u1EC7\u0229\u1E1D\u0119\u1E19\u1E1B\u0247\u025B\u01DD]/g},
      {'base':'f', 'letters':/[\u0066\u24D5\uFF46\u1E1F\u0192\uA77C]/g},
      {'base':'g', 'letters':/[\u0067\u24D6\uFF47\u01F5\u011D\u1E21\u011F\u0121\u01E7\u0123\u01E5\u0260\uA7A1\u1D79\uA77F]/g},
      {'base':'h', 'letters':/[\u0068\u24D7\uFF48\u0125\u1E23\u1E27\u021F\u1E25\u1E29\u1E2B\u1E96\u0127\u2C68\u2C76\u0265]/g},
      {'base':'hv','letters':/[\u0195]/g},
      {'base':'i', 'letters':/[\u0069\u24D8\uFF49\u00EC\u00ED\u00EE\u0129\u012B\u012D\u00EF\u1E2F\u1EC9\u01D0\u0209\u020B\u1ECB\u012F\u1E2D\u0268\u0131]/g},
      {'base':'j', 'letters':/[\u006A\u24D9\uFF4A\u0135\u01F0\u0249]/g},
      {'base':'k', 'letters':/[\u006B\u24DA\uFF4B\u1E31\u01E9\u1E33\u0137\u1E35\u0199\u2C6A\uA741\uA743\uA745\uA7A3]/g},
      {'base':'l', 'letters':/[\u006C\u24DB\uFF4C\u0140\u013A\u013E\u1E37\u1E39\u013C\u1E3D\u1E3B\u017F\u0142\u019A\u026B\u2C61\uA749\uA781\uA747]/g},
      {'base':'lj','letters':/[\u01C9]/g},
      {'base':'m', 'letters':/[\u006D\u24DC\uFF4D\u1E3F\u1E41\u1E43\u0271\u026F]/g},
      {'base':'n', 'letters':/[\u006E\u24DD\uFF4E\u01F9\u0144\u00F1\u1E45\u0148\u1E47\u0146\u1E4B\u1E49\u019E\u0272\u0149\uA791\uA7A5]/g},
      {'base':'nj','letters':/[\u01CC]/g},
      {'base':'o', 'letters':/[\u006F\u24DE\uFF4F\u00F2\u00F3\u00F4\u1ED3\u1ED1\u1ED7\u1ED5\u00F5\u1E4D\u022D\u1E4F\u014D\u1E51\u1E53\u014F\u022F\u0231\u00F6\u022B\u1ECF\u0151\u01D2\u020D\u020F\u01A1\u1EDD\u1EDB\u1EE1\u1EDF\u1EE3\u1ECD\u1ED9\u01EB\u01ED\u00F8\u01FF\u0254\uA74B\uA74D\u0275]/g},
      {'base':'oi','letters':/[\u01A3]/g},
      {'base':'ou','letters':/[\u0223]/g},
      {'base':'oo','letters':/[\uA74F]/g},
      {'base':'p','letters':/[\u0070\u24DF\uFF50\u1E55\u1E57\u01A5\u1D7D\uA751\uA753\uA755]/g},
      {'base':'q','letters':/[\u0071\u24E0\uFF51\u024B\uA757\uA759]/g},
      {'base':'r','letters':/[\u0072\u24E1\uFF52\u0155\u1E59\u0159\u0211\u0213\u1E5B\u1E5D\u0157\u1E5F\u024D\u027D\uA75B\uA7A7\uA783]/g},
      {'base':'s','letters':/[\u0073\u24E2\uFF53\u00DF\u015B\u1E65\u015D\u1E61\u0161\u1E67\u1E63\u1E69\u0219\u015F\u023F\uA7A9\uA785\u1E9B]/g},
      {'base':'t','letters':/[\u0074\u24E3\uFF54\u1E6B\u1E97\u0165\u1E6D\u021B\u0163\u1E71\u1E6F\u0167\u01AD\u0288\u2C66\uA787]/g},
      {'base':'tz','letters':/[\uA729]/g},
      {'base':'u','letters':/[\u0075\u24E4\uFF55\u00F9\u00FA\u00FB\u0169\u1E79\u016B\u1E7B\u016D\u00FC\u01DC\u01D8\u01D6\u01DA\u1EE7\u016F\u0171\u01D4\u0215\u0217\u01B0\u1EEB\u1EE9\u1EEF\u1EED\u1EF1\u1EE5\u1E73\u0173\u1E77\u1E75\u0289]/g},
      {'base':'v','letters':/[\u0076\u24E5\uFF56\u1E7D\u1E7F\u028B\uA75F\u028C]/g},
      {'base':'vy','letters':/[\uA761]/g},
      {'base':'w','letters':/[\u0077\u24E6\uFF57\u1E81\u1E83\u0175\u1E87\u1E85\u1E98\u1E89\u2C73]/g},
      {'base':'x','letters':/[\u0078\u24E7\uFF58\u1E8B\u1E8D]/g},
      {'base':'y','letters':/[\u0079\u24E8\uFF59\u1EF3\u00FD\u0177\u1EF9\u0233\u1E8F\u00FF\u1EF7\u1E99\u1EF5\u01B4\u024F\u1EFF]/g},
      {'base':'z','letters':/[\u007A\u24E9\uFF5A\u017A\u1E91\u017C\u017E\u1E93\u1E95\u01B6\u0225\u0240\u2C6C\uA763]/g}
    ];

    for(var i=0; i< default_diacritics_map.length; i++) {
      word = word.replace(default_diacritics_map[i].letters, default_diacritics_map[i].base);
    }
    return word;
  }

  function set_error_class_for_fields(fields_with_errors) {
    $('.fieldWithErrors').each(function() {
      $(this).removeClass('fieldWithErrors');
    });

    $.each(fields_with_errors, function(key, field) {
      var current_field = $("#"+field);
      var parent_div = current_field.closest('div');
      parent_div.addClass('fieldWithErrors');
      $(`label[for='${field}']`).each(function() {
        // Set to label if not already has it
        parent_div = $(this).closest('div');
        if (!parent_div.hasClass('fieldWithErrors')) {
          parent_div.addClass('fieldWithErrors');
        }
      });
    });
  }

  function unassignable_dialog_text(reason) {
    if (reason === 'unassignable_chat_disabled_at_school_level') {
      return 'Your institution has disabled chat support.<br/>' +
             "You can't assign group chat and partner chat activities.";
    } else if (reason === 'unassignable_chat_activity') {
      return 'The chat feature is disabled in your course.<br>' +
             "You can't assign partner chat activities." +
             '<br /><br />' +
             'To change this setting, return to your <b>Dashboard</b>, ' +
             'click course settings (the gear icon) for your course, ' +
             'click the <b>Edit Course</b> option, and then click the ' +
             '<b>Content</b> tab.';
    } else if (reason === 'unassignable_teacher_edition') {
      return 'This content is intended for instructors only and is not assignable to students';
    } else if (reason === 'unassignable_ai_virtual_chat') {
      return 'The AI chat feature is disabled in your course.<br>' +
             "You can't assign AI chat activities." +
             '<br /><br />' +
             'To change this setting, return to your <b>Dashboard</b>, ' +
             'click course settings (the gear icon) for your course, ' +
             'click the <b>Edit Course</b> option, and then click the ' +
             '<b>Content</b> tab.';
    } else {
      return 'The <b>Access Level</b> or <b>Component</b> setting for this course does ' +
             'not allow students to view this activity.' +
             '<br /><br />' +
             'To change these settings, return to your <b>Dashboard</b>, ' +
             'click course settings (the gear icon) for your course, ' +
             'click the <b>Edit Course</b> option, and then click the ' +
             '<b>Content</b> tab.' +
             '<br /><br />' +
             '<b>Note:</b> If your institution uses a site license for this program  ' +
             'you will be unable to change the <b>Access</b> Level or <b>Component</b> ' +
             'settings.';
    }
  }

  function unassignable_dialog_title(reason) {
    if (reason === 'unassignable_chat_disabled_at_school_level') {
      return 'Chat support disabled';
    } else if (reason === 'unassignable_chat_activity') {
      return 'Chat support disabled';
    } else if (reason === 'unassignable_teacher_edition') {
      return 'Teacher Edition';
    } else {
      return 'Access Level';
    }
  };

  function unassignable_dialog() {
    var dialog_links = $('.js-unassignable-msg-link');
    if (dialog_links.length > 0) {
      $('body').append('<div id="unassignable-msg"></div>');
      let dialog_box = $('#unassignable-msg');
      dialog_box.hide();
      // this is to avoid duplicating the dialog on click. From standards based assigning
      // we call this function when the vue component is updated and that was duplicating the dialog.
      dialog_links.unbind('click');
      dialog_links.click(function(evt) {
        evt.preventDefault();
        var reason = $(evt.currentTarget).attr('js-data-unassignable-reason');

        dialog_box.html(unassignable_dialog_text(reason));
        dialog_box.dialog({title: unassignable_dialog_title(reason), modal: true});
      });
    };
  }

  function unassignable_student_dialog() {
    var dialog_links =  $('.js-unassignable-msg-student-link');
    var dialog_element =  $('.js-modal-access-additional-content');
    if (dialog_links.length && dialog_element.length) {
      dialog_links.click(() => {
        dialog_element.vhlModal('open');
      });
    };
  }

  function insert_text_into_contenteditable_div( text ) {
    document.execCommand( 'insertText', false, text ) || document.execCommand( 'paste', false, text );
  }

  function insert_text_into_input_or_textarea( text, jq_elm ) {
    jq_elm.insertAtCaret( text );
  }

  return {
    build_ajax_url: build_ajax_url,
    bind_prevent_default: bind_prevent_default,
    createJSErrorLog: createJSErrorLog,
    disable_link_hover: disable_link_hover,
    gear_click_event: gear_click_event,
    init: init,
    initialize_datepicker: initialize_datepicker,
    insert_text_into_contenteditable_div: insert_text_into_contenteditable_div,
    insert_text_into_input_or_textarea: insert_text_into_input_or_textarea,
    jquery_dialog_setup: jquery_dialog_setup,
    metaTagContent: metaTagContent,
    move_jquery_modal_delete_link_into_button_pane: move_jquery_modal_delete_link_into_button_pane,
    parse_query_string: parse_query_string,
    program_id: program_id,
    prep_common_jquery_modal: prep_common_jquery_modal,
    preventWarningsAfterTimeout: preventWarningsAfterTimeout,
    remove_diacritics: remove_diacritics,
    set_error_class_for_fields: set_error_class_for_fields,
    shouldPreventWarningsAfterTimeout: shouldPreventWarningsAfterTimeout,
    unassignable_dialog: unassignable_dialog,
    unassignable_student_dialog: unassignable_student_dialog,
    unescape_xml_entities: unescape_xml_entities
  };
})();

$.fn.synchronous_submit = function() {
  return this.each(function() {
    $.ajax({
      url: $(this).attr('action'),
      type: $(this).attr('method'),
      data: $(this).serialize(),
      dataType: 'script',
      async: false,
      beforeSend: function(xhr) {xhr.setRequestHeader("Accept", "text/javascript");}
    });
  });
}

$.fn.show_jquery_dialog = function(params){
  VHL.Common.jquery_dialog_setup(this, params);
}

$.urlParam = function(name) {
  var results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(window.location.href);
  if (results === null) {
    return null;
  } else {
    return results[1];
  }
}

$(document).ready(
  function() {
    VHL.Common.init();

    var modules = _(angular.element(document).find('[vhl-app]')).map(
      function(elm) {
        return angular.element(elm).attr('vhl-app')
      }
    );
    if (_(modules).contains('instructor_notes_app')) {
      modules.push('get_help_app')
    };

    if (modules.length > 0) {
      /**
       * To avoid a race condition when the page contains glossable content,
       * where the gloss processing alters the elements in the DOM and wipes
       * out their event bindings, if the page contains glossable content,
       * hold off on starting the bootstrap process until an Event is
       * dispatched notifying that the gloss processing is complete.
       */
      var glossContainer = document.querySelector('.js-glossable-content');

      if (glossContainer) {
        document.addEventListener(
          'gloss_processing_complete',
          function() {
            angular.bootstrap(document, modules);
          }
        );
      } else {
        angular.bootstrap(document, modules);
      }
    }
  }
);
