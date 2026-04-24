import { OpenEndedWithWordbank } from 'mae';
document.addEventListener('DOMContentLoaded', () => {
  const openEndedQuestions = document.querySelectorAll('[data-question-type="open_ended"]');
  openEndedQuestions.forEach( (openEndedNode) => {
    const openQuestion = new OpenEndedWithWordbank(openEndedNode);
    openQuestion.addAria();
  });
});
