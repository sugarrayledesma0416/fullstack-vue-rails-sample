window.zESettings = {
  webWidget: {
    chat: {
      departments: {
        enabled: ['vhlcentral Support'],
        select: 'vhlcentral Support',
      },
    },
  },
};

window.addEventListener('load', () => {
  const logoutLink = document.querySelector('.js-logout-link');
  const chatWidgetButton = document.querySelector('.js-zendesk-chat-widget');
  const unreadIndicator = document.querySelector('.js-unread-indicator');
  let isWidgetOpen = false;

  const toggleWidget = () => {
    zE('messenger', isWidgetOpen ? 'close' : 'open');
  };

  const updateUnreadIndicator = (count) => {
    if (count) {
      unreadIndicator.style.background = '#CC3333';
      unreadIndicator.textContent = count;
      unreadIndicator.classList.remove('u-dis-none');
    } else {
      unreadIndicator.textContent = '0';
      unreadIndicator.classList.add('u-dis-none');
    }
  };

  if (logoutLink && typeof zE !== 'undefined') {
    logoutLink.addEventListener('click', () => zE('webWidget', 'logout'));
  }

  if (chatWidgetButton) {
    chatWidgetButton.addEventListener('click', toggleWidget);
  }

  zE('messenger:on', 'open', () => { isWidgetOpen = true; });
  zE('messenger:on', 'close', () => { isWidgetOpen = false; });
  zE('messenger:on', 'unreadMessages', updateUnreadIndicator);
});
