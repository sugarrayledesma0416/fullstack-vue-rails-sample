# VHL Chat

## Chat Requirements

### Terminology
* **Chat**: The chat application provides a utility for students and instructors within the same course to send each other text messages, and to participate in 1 on 1 audio/video chats. The audio/video chat sessions may be recorded if the instantiation of the chat app is configured for recording.
* **Chat settings**: Chat has configurable components, which are defined by a [settings object](#settings) in javascript.
* **live chat**: When "live chat" is enabled in course settings, users will see a chat UI on most m3 pages. They can send text messages and video/audio chat invitations to other users in their course. If no configuration is provided, the defaults will produce a "live chat". [Live chat configuration](#livechat-config)
* **partner chat** or "pchat": When "partner chat" is enabled in the course settings, users will see a chat UI on partner chat activity pages only. Partner chat provides functionality for the current user to invite another user in their course to join them on the partner chat activity from which the invite is sent. Users can record their video/audio sessions in partner chat. The recorded sessions become part of the activity submission. [Parnter chat configuration](#pchat-config)
* **Pubnub**: An external service that provides chat text messages and chat invitations.
* **Tokbox**: An external service that handles video streaming and recording.
* **VHL Messaging Client Wrapper** or "client wrapper": A library providing an abstraction for Pubnub and Tokbox specific api calls. https://github.com/vhl/dirt-driver-chat


## Initialization

### 1. Chat configuration, defined in M3
**These are populated by the server in /app/views/layouts/_common_header.html.erb**

* **activity id**: This is used as pchat recording metatdata. It is empty if we are not on an activity page.
* **activity type**: If user is on a partner chat activity, configure chat as a pchat. If not, configure as live chat.
* **activity url**: This is sent as metadata of a pchat invite.
* **course id**: The m3 course id for the current user. It is used in chat rostering and as pchat recording metadata.
* **load ui**: If this is false, we run chat "behind the scenes". No UI is shown to the user.
* **permissions**: This is current course's chat level permissions for partner chat and live chat.
* **pubnub configured**: If false, the application is missing configuration for the Pubnub api key.
* **roster**: This represents the current user's chat roster, which maps to their open enrollments on chat enabled courses.
* **session**: if the user has a current Pubnub session token stored in a VHL cache.
* **school id**: id associated with the current user and course.
* **section id**: m3 section id for the current user. It is used for chat rostering and as pchat recording metatdata.
* **tokbox api key**: undefined, the application is missing configuration for the Tokbox api key.
* **user id**: user's m3 id. This is used for chat rostering and pchat recording metatdata.
* **join partner chat session**: true if the user is opening a new tab via a pchat invite. This data is encoded in the url.

### <a name="settings"></a>2. Settings for live chat or partner chat
<a name="livechat-config"></a>**Live chat settings:**
```javascript
{
  chatSession: undefined, // This is either type undefined or an object found in the chat auth cache,
  sectionId: 456,
  courseId: 123,
  myUuid: "789", // All uuid's are stored as strings. (TODO: why?)
  canRecord: false, // recording is not enabled in live chat.
  hasVideoPlayback: false, // video playback is not enabled in live chat.
  showRosterPanelBody: true, // Live chat UI should include a chat roster that opens and closes.
  chatContainer: '.js-live-chat-container', // The chat roster is appened to this container.
  usePartnerChatActivityStyle: false, // Don't use pchat specific styles
  startCallButton: '.js-start-call' // This selector represents the invite call button
}

```
<a name="pchat-config"></a>**Partner chat settings:**
```javascript
{
  chatSession: undefined, // This is either type undefined or an object found in the chat auth cache,
  schoolId: schoolId(dependencies.schoolIds),
  sectionId: 456,
  activityId: dependencies.activityId,
  activityUrl: window.location.pathname,
  joinPartnerChatSession: joinPartnerChatSessionFromParams(),
  courseId: 123,
  myUuid: "789", // All uuid's are stored as strings. (TODO: why?)
  canRecord: true, // recording is enabled in partner chat.
  hasVideoPlayback: true, // video playback is enabled in partner chat.
  showRosterPanelBody: false, // The chat UI cannot be hidden in a partner chat.
  chatContainer: '.js-pchat-activity-container', // The chat roster is appened to this container.
  usePartnerChatActivityStyle: true, // Use pchat specific styles
  startCallButton: '.js-start-pchat-activity' // This selector represents the invite call button
}
```
