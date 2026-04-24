# Chat sequence

## The page loads

`init_chat.js` is brought in via `chat_bootstrap.js` (which in turn is required by `application-music-v1.js`). It calls `VHL.Chat.init`, which is defined in `chat_config.js`, and passes it the `VHL.Chat.CONFIG` hash that is populated server-side in `app/views/layouts/_common_header.html.erb`.

## User A sends invitation to User B

User A clicks the `startCallButton`. The selector that identifies this button is set in `chat_config.js` based on whether the `config.activityType` is a partner-chat activity (including info-gap-partner-chat).

`chat_view.js`: The click handler for the `startCallButton` invokes `startCall` on the controller.

`controller_factory.js`, `startCall`: invokes `initiatePartnerChat` on `cAdapter`, which is set in the `cWrapperSuccess` callback that happens after `cWrapper.setup()` succeeds in `chat_config.js`. Passes it a success callback that invokes `sendInvite` on the pChatAdapter passed to the callback.

`cw-combine.js`: maps session ID to session data and returns a sessionAdapter (created in `__constructSessionAdapter`) specific to the session.

`controller_factory.js`, back to the success callback: call `sendInvite` on the session adapter.

`cw-combine.js`, `__sendInvite`: uses PubNub SDK to publish the invite message.

## User B gets invitation

`vhl-msg-event-handler.js`: `showReceivedInformation` calls `renderView` on controller

`controller_factory.js`: calls `update` on `_view`

## User B accepts invitation

`chat_view.js`, click handler for `.js-accept-invitation`: call `beginPartnerChatSession` on controller, passing it a pChatEventHandler.

`controller_factory.js`, `beginPartnerChatSession`: pull metadata from chatAdapter, including whether to accept on new tab.

back to chat-view handler: _either_ display live chat _or_ dismiss invitation on current tab; call `acceptInvitation` on controller.

`controller_factory.js`, `acceptInvitation`: if accepting on new tab, assemble the URL for the new tab and open it.  If live chat, call `acceptInvite` (uses PubNub SDK) on `_pChatAdapter`, passing it the `_pChatEventHandler` (`VHL.Msg.pChatEventHandler`) that was passed in during view's click handler. `_pChatEventHandler` will be assigned to `_externalPChatEventHandler`, which is used in `_fireEvent`.

## Media Streams

`vhl-msg-pchat-event-handler.js`, on `INITIATE` (sender has created media stream, is ready to share with recipient): `createRecipientMediaStream`

`createRecipientMediaStream`: calls `createMediaStream` on adapter, passing in a success callback.

`cw-combine.js`'s `createMediaStream`: creates `VHL.Msg.MediaStream.MediaStreamManager` (also defined in `cw-combine.js`) and calls `createMediaStream` on it, passing it a callback.

`MediaStreamManager`'s `createMediaStream`: creates stream, gets `streamData`, passes it to success callback.

back to `cw-combine.js`'s `createMediaStream`, the success callback: receives `streamData` as `mediaData`, passes it to `createRecipientMediaStream` callback.

`vhl-msg-pchat-event-handler.js`, callback in `createRecipientMediaStream`: call `showMyMediaStream` on adapter, passing in a success callback.

`cw-combine.js`, `showMyMediaStream`: set `enable_audio` and `enable_video` based on `_externalMediaOptions` and call `publishMyMediaStream` on `_mediaStreamMgr`, passing it the success callback that was passed in from the pchat event handler's callback in `createRecipientMediaStream`.

`cw-combine.js`, `__publishMyMediaStream`: call `_callStreamingProvider` and pass it the callback from `showMyMediaStream`.

`OpenTok` stuff happens, and the callback runs: call `confirmPairing` on the pChat adapter, then call `playPartnerMediaStream` on pChat adapter.
