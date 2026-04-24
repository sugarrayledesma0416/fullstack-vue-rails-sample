VHL.CompositionActivity = (function() {
  function init() {
    $('.composition_upload_container').each(function() {
      var composition_container   = $(this).parent('.composition_container');

      var parent_container        = composition_container.parent('.composition_upload');
      var close_link_div          = parent_container.find('.close_link');
      var close_link              = close_link_div.find('[data-link="close_container"]');

      var data_attributes         = $(this).data('js-upload-params');
      var endpoint                = data_attributes.endpoint_url;
      var hidden_field_id         = $('#'+data_attributes.hidden_field_id);
      var allowed_file_extensions = data_attributes.allowed_file_types.split(',');

      var upload_status_div       = composition_container.find('.upload_status');

      var link_container          = composition_container.siblings('.composition_link_container');
      var remove_saved_file_link  = link_container.find('.remove_attachment_link');
      var file_types_message      = composition_container.find('[data-js-composition="file_types_link"]');

      var token = $("meta[name='csrf-token']").attr("content");

      var uploader = $(this).fineUploader({
        debug: true,
        request: {
            endpoint: endpoint,
            paramsInBody: true,
            inputName: 'uploaded_file',
            forceMultipart: true,
            customHeaders: {"X-CSRF-Token": token},
            params: { authenticity_token: token, navigator_user_agent: navigator.userAgent }
        },
        deleteFile: {
            endpoint: endpoint,
            enabled: true,
            forceConfirm: true,
            customHeaders: {"X-CSRF-Token": token},
            confirmMessage: "Are you sure you want to remove {filename}?",
            deletingStatusText: "Removing...",
            deletingFailedText: "Removing failed",
            params: { authenticity_token: token }
        },
        validation: {
          sizeLimit: 10485760,
          allowedExtensions: allowed_file_extensions
        },
        messages: {
          sizeError: 'File size must be 10 MB or smaller',
          typeError: 'You tried to upload a file with an invalid extension.'
        },
        multiple: false,
        text: {
          deleteButton: 'Remove'
        },
        showMessage: function(message) {
          message_failed(message);
          if(message.indexOf("invalid extension") !== -1){
            show_file_types_message();
          } else{
            hide_file_types_message();
          }
        }
      });

      set_default_button_text();
      set_default_message();

      hidden_field_id.on('change', function(event){
        activity_unsaved_work_warning();
      });

      $(this).on('upload', function(id, name) {

        remove_saved_links();
        hide_file_types_message();
        message_clear_messages();
      });
      $(this).on('progress', function() {
        append_parentheses();
        enable_cancel();
        disable_delete();
      });
      $(this).on('cancel', function() {
        clear_hidden_field();
        ui_deactivate_container();
        set_default_button_text();
        set_default_message();
      });
      $(this).on('complete', function(event, id, name, response) {
        disable_cancel();
        ui_activate_container();
        message_clear_messages();
        if (response.success) {
          var container = $(this);
          hidden_field_id.val(response.attachment_id);
          remove_saved_links();
          activity_unsaved_work_warning();
          message_upload_success();
          hide_file_types_message();
          create_download_link(container, response.download_url);
          set_upload_button_text('replace');
          enable_delete();
        } else {
          clear_hidden_field();
          message_failed(response.reason);
        }
      });
      $(this).on('deleteComplete', function(event, id, xhr, is_error) {
        message_clear_messages();
        if (is_error) {
          response = parseResponse(xhr);
          message_failed(response.reason);
        } else {
          ui_deactivate_container();
          clear_hidden_field();
          message_file_remove_success();
          remove_saved_links();
          set_upload_button_text('upload');
        }
      });
      $(this).on('error', function(id, name, reason) {
        clear_file_name();
        remove_saved_links();
        clear_hidden_field();
        set_upload_button_text('upload');
        upload_status_div.html('<span class="normal failure">' + reason + ' upload failed.</span>');
      });
      $(this).on('submit', function(event, id) {
        if (hidden_field_id.val().length > 0) {
          // submit the value of current attachment id when uploading a new file
          // so we can replace the previous attachment with the new one
          uploader.fineUploader('setParams', { previous_attachment_id: hidden_field_id.val() } );
        }
      });
      $(this).on('submitDelete', function(event, id) {
        // will create a route like /composition_attachments/45 (and then add the uuid field that fine uploader
        // always sends as an optional query param)
        uploader.fineUploader('setDeleteFileEndpoint', endpoint + '/' + hidden_field_id.val() + '?uuid=' );
      });
      if (remove_saved_file_link.length > 0) {
        remove_saved_file_link.on('click', function(click_event){
          $.ajax({
            url: $(this).attr('href'),
            type: "delete",
            dataType : 'json',
            success: function(response){
              message_file_remove_success();
              remove_saved_links();
              clear_hidden_field();
            },
            error: function(xhr, status, error){
              response = parseResponse(xhr);
              message_failed(response.reason);
             },
            complete: function(){ }
          });
          click_event.preventDefault();
        });
      }

      // Clears the Hidden Field where the Attachment Information is stored.
      function clear_hidden_field() {
        hidden_field_id.val('');
      }

      // Clears the name for an existing uploaded file when uploading a new file.
      function clear_file_name() {
        composition_container.find('.qq-upload-list').find('li.qq-upload-fail').hide();
      }

      // Checks if the hidden field has an Attachment stored.
      function has_attachment() {
        return hidden_field_id.val() != "";
      }

      // Removes the "View you submission" and "Remove uploaded file" links.
      function remove_saved_links() {
        link_container.html('');
      }

      // Make Link to view Submission after Uploading.
      function create_download_link(container, download_url) {
        // Finds the filename relative to which upload container we are using. Will be important for Instructor Grading.
        var filename_span = container.find('.qq-upload-file');
        var filename_text = filename_span.text();
        filename_span.html('<a href="' + download_url + '" class="submission" target="_blank">' + filename_text + '</a>');
      }

      // Shows a message when your file is successfully removed.
      function message_file_remove_success() {
        upload_status_div.html('<span class="normal">' + 'Your file has been successfully removed.' + '</span>');
        clear_hidden_field();
        hidden_field_id.change();
        set_default_button_text();
      }

      // Shows a message when your file upload/removal fails.
      function message_failed(reason) {
        ui_activate_container();
        composition_container.find('.qq-upload-success').remove();

        if (upload_status_div.find('.normal failure')) {
          upload_status_div.append('<span class="reason">' + reason + '</span>');
        } else {
          upload_status_div.html('<span class="normal failure">Upload failed.</span><span class="reason">' + reason + '</span>');
        }
      }

      // Clear previous messages - both successes and failures.
      function message_clear_messages() {
        upload_status_div.html("");
      }

      // Hide the link to view a list of allowed file types.
      function hide_file_types_message() {
        if (!file_types_message.hasClass('hidden_helper')) {
          file_types_message.addClass('hidden_helper');
        }
      }

      // Adds parentheses around the file size when a file is being uploaded.
      function append_parentheses() {
        var size_container = composition_container.find('.qq-upload-size');
        var upload_size = size_container.text();

        upload_size = '(' + upload_size + ')';
        size_container.text(upload_size);
      }

      // This activates the upload container, changing the styling
      // and adding a "close" button for when it is being used.
      function ui_activate_container() {
        parent_container.addClass('active');
        close_link_div.removeClass('hidden_helper');
        close_link.on("click", function() {
          message_clear_messages();
          parent_container.find('.qq-upload-fail').remove();
          ui_deactivate_container();
          hide_file_types_message();
          set_default_message();
          return false;
        });
      }

      function ui_deactivate_container() {
        parent_container.removeClass('active');
        close_link_div.addClass('hidden_helper');
        close_link.off("click");
      }

      // Sets the default text for the Upload Button
      function set_default_button_text() {
        if (has_attachment()) {
          set_upload_button_text('replace');
        } else {
          set_upload_button_text('upload');
        }
      }

      // Sets a default message if the user has no file.
      function set_default_message() {
        if (!has_attachment()) {
          upload_status_div.html('<span class="default">No file chosen</span>');
        }
      }

      // Changes Upload Button Text
      function set_upload_button_text(message) {
        var label = message + " file";
        var upload_button = parent_container.find('.qq-upload-button div');
        upload_button.text(label);
        var upload_label = parent_container.find('.qq-upload-button input');
        upload_label.attr("title", label);
      }

      // Show the link to view a list of allowed file types.
      function show_file_types_message() {
        if (file_types_message.hasClass('hidden_helper')) {
          file_types_message.removeClass('hidden_helper');
        }
      }

      // Shows a message when the upload is successful.
      function message_upload_success() {
        var grading_reminder;

        // Checks what buttons are rendered to display specific messages on grading sets.
        var done_button = $('input[data-button="done"]');
        var next_button = $('input[data-button="next"]');

        if (done_button.length > 0) {
          grading_reminder = "You must still click done to complete grading."
        } else if (next_button.length > 0) {
          grading_reminder = "You must still click next to continue grading."
        }

        // Displays success message based on page
        var success_message = 'Your file has been successfully added. ';
        var activity_reminder = 'You must still submit to complete the activity.';

        if (is_composition_grading()) {
          upload_status_div.html('<span class="success">' + success_message + grading_reminder + '</span>');
        } else {
          upload_status_div.html('<span class="success">' + success_message + activity_reminder + '</span>');
        }
      }

      function activity_unsaved_work_warning(){
        //has_unsaved_work is not defined in review work and grading sets (instructor side),
        // only when viewing/submitting the activity like a student
        if(typeof(has_unsaved_work) == 'function'){
          has_unsaved_work();
        }
      }

      // Check if we are on Composition Grading
      function is_composition_grading() {
        return $('body').hasClass('composition_grading');
      }

      // Return button data for submit buttons.
      function submit_buttons() {
        if (is_composition_grading()) {
          return ["next", "done"]
        } else {
          return ["save", "submit", "answers", "check"]
        }
      }

      // Disables button to cancel the upload
      function disable_cancel() {
        composition_container.find('.qq-upload-cancel').hide();
      }

      // Enables button to cancel the upload
      function enable_cancel() {
        composition_container.find('.qq-upload-cancel').show();
      }

      // Disables button to delete the uploaded file
      function disable_delete() {
        composition_container.find('.qq-upload-delete').hide();
      }

      // Enables button to delete the uploaded file
      function enable_delete() {
        composition_container.find('.qq-upload-delete').show();
        composition_container.find('.qq-upload-delete').attr("title", "remove file");
      }
    });
  }

  function parseResponse(xhr) {
      var response;
      try {
        response = jQuery.parseJSON(xhr.responseText);
      }
      catch(error) {
        console.log('Error when attempting to parse xhr response text (' + error + ')', 'error');
        response = {};
      }
      return response;
  }

  return {
    init:init
  }

})();

$(document).ready(function() {
  VHL.CompositionActivity.init();
});
