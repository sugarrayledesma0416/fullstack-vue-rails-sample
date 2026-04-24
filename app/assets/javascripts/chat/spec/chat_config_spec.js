var chat_dependencies =
      {
        activityId: "",
        activityType: "",
        courseId: 200,
        loadUI: true,
        permissions: {partner_chat_enabled: true, live_chat_enabled: true},
        pubnub_configured: true,
        roster: {"courses":[{"id":"course_200","name":"course 1","sections":[{"id":"section_100","name":"factory section name","users":[]}]}]},
        session: {},
        schoolIds: [55],
        sectionId: 100,
        tokboxApiKey: "",
        userId: 123
      };

$(document).ready(function() {
  if(_.isEqual(VHL.Chat.CONFIG, chat_dependencies)) {
    $('#page_container').prepend($('<div class="js-spec-chat-dependencies-ok"></div>'));
  }
});
