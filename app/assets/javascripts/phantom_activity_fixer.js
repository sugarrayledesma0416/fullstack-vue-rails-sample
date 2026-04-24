$(document).ready(function(){
    const phantomActivityFixer = new PhantomActivityFixer();
    phantomActivityFixer.init();
});

class PhantomActivityFixer {
  init() {
    this.selectPhantomActivity = document.querySelector('.js-select-phantom-activity');
    this.activityIdFirst = document.querySelector('.js-activity-id-first');
    this.activityIdSecond = document.querySelector('.js-activity-id-second');
    this.activitySecond = document.querySelector('.js-activity-second');

    this.selectPhantomActivity.addEventListener('change', (evt) => {
      this.hideActivityField(evt.target.value);
    });
  }

  hideActivityField(option) {
    if (option === '1') {
      this.activitySecond.removeAttribute('required');
      this.activityIdSecond.classList.add('u-hidden');
    }else{
      this.activitySecond.setAttribute('required',true);
      this.activityIdSecond.classList.remove('u-hidden');
    }
  }
}

$(document).submit(function() {
  confirmSubmit();
});

function confirmSubmit()
{
  confirm("Verify the selected option, as well as the id of the activity.\nAre you sure you wish to continue?");
}
