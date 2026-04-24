document.addEventListener('DOMContentLoaded', () => {
  const eventsToListen = ['click', 'keyup']
  const closeBtn = document.querySelector('.js-close-rubric-btn');
  eventsToListen.forEach(
    (eventType) => {
      closeBtn.addEventListener(
        eventType, (evt) => {
          if(eventType === 'click' || evt.keyCode === 13) {
            window.close();
          }
        }
      );
    }
  );
});
