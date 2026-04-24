import { processChineseText } from 'shared/utils';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    const activityContentElm = document.getElementById('activity_shell');
    activityContentElm.querySelectorAll('[lang="zh-Latn"]').forEach(
      (node) => {
        node.setAttribute('aria-hidden', 'true');
      }
    );

    activityContentElm.querySelectorAll('.js-comment-text').forEach(
      (node) => {
        node.innerHTML = processChineseText(node.textContent);
      }
    );
  }
);
