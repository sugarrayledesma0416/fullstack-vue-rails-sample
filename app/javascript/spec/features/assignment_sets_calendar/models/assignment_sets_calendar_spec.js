import AssignmentSetsCalendar
  from 'features/assignment_sets_calendar/models/assignment_sets_calendar';
import MockDate from 'mockdate';
MockDate.set(new Date(2022, 5, 15));


describe('AssignmentSetsCalendar', () => {
  describe('firstSelectedDate', () => {
    it('returns the first day of the current month', () => {
      const assignmentSetsCalendar = new AssignmentSetsCalendar('2022-05-20', '2022-09-04');

      expect(
        assignmentSetsCalendar.firstSelectedDate()
      ).toEqual(new Date(2022, 5, 1));
    });

    describe('when the courseStartDate is after the beginning of the current month', () => {
      const assignmentSetsCalendar = new AssignmentSetsCalendar('2022-06-02', '2022-09-04');

      it('returns the course start date', () => {
        expect(
          assignmentSetsCalendar.firstSelectedDate()
        ).toEqual(new Date(2022, 5, 2));
      });
    });
  });

  describe('lastSelectedDate', () => {
    it('returns the last day of the current month', () => {
      const assignmentSetsCalendar = new AssignmentSetsCalendar('2022-05-20', '2022-09-04');

      expect(
        assignmentSetsCalendar.lastSelectedDate()
      ).toEqual(new Date(2022, 5, 30));
    });

    describe('when the courseEndDate is before the end of the current month', () => {
      const assignmentSetsCalendar = new AssignmentSetsCalendar('2022-04-02', '2022-06-04');

      it('returns the course end date', () => {
        expect(
          assignmentSetsCalendar.lastSelectedDate()
        ).toEqual(new Date(2022, 5, 4));
      });
    });
  });
});
