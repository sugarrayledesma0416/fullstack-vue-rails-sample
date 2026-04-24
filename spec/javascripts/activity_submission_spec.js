describe("VHL.Activity.Submission", function() {
  describe("when the ajax call is successful", function() {
    beforeEach(function () {
      spyOn(VHL.Activity, 'is_storing_work')
      spyOn($, "ajax").andCallFake(function(options) {
        options.success();
      });
    });

    //this is a temporary fix to be able to send a message to a partner that the
    // activity has been submitted
    it('triggers the partner_chat_submitted event on the submit button', function() {
      var trigger_spy = spyOn($.fn, 'trigger')
      VHL.Activity.Submission.ajax_submission()
      expect(trigger_spy).toHaveBeenCalledWith('partner_chat_submitted');
    });
  });
})
