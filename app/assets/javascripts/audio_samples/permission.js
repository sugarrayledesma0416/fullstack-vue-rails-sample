var ACCEPT_URL = '/audio_sample_agreement';
var CONTENT_TYPE = 'application/x-www-form-urlencoded; charset=UTF-8';

var csrfToken = $("meta[name='csrf-token']").attr('content');
var userId = $("meta[name='VHL.user_id']").attr('content');

function acceptTerms() {
  var invocation = new XMLHttpRequest();
  if (invocation) {
    invocation.open('POST', ACCEPT_URL, true);
    invocation.setRequestHeader('X-CSRF-Token', csrfToken);
    invocation.setRequestHeader('Content-Type', CONTENT_TYPE);
    invocation.onreadystatechange = function responseCallback() {
      if (invocation.readyState === 4 && invocation.status === 200) {
        console.log(invocation.responseText);
        window.location.reload(true);
      }
    };
  }

  invocation.send('user_id=' + userId + '&context=project_george' +
      '&allows_recording=true');
}

function redirectToHome() {
  document.location.href = '/';
}

$('#agree').click(acceptTerms);
$('#disagree').click(redirectToHome);
