function log_chat_link(source){
  $.ajax({
    type: "put",
    url: "/chat_click_logs/log",
    data: {chat_click_log : { source_tag : source,
                              browser : navigator.appCodeName,
                              os : navigator.platform,
                              url : location.pathname}},
    dataType: "json"
  });
}
