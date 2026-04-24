//= require late_work

describe('VHL.LateWork', function() {
  var student_1_id, student_1_name_cell, student_2_id, student_1_checkbox;
  var student_2_checkbox, submission_dialog;

  beforeEach(function() {
    loadFixtures('late_work.html');
    VHL.LateWork();
    submission_dialog = $('.js-accept-late-work-dialog');
    student_1_name_cell = $('span:contains(Bahringer, Blaise)').parent('td');
    student_1_id = student_1_name_cell.data('student-id');
    student_2_id = $('span:contains(Lind, Jo)').parent('td').data('student-id');
    student_1_checkbox = $('.js-student-checkbox[data-student-id="' + student_1_id + '"]');
    student_2_checkbox = $('.js-student-checkbox[data-student-id="' + student_2_id + '"]');
    student_1_row = $('tr[data-student-id="' + student_1_id + '"]');
    student_2_row = $('tr[data-student-id="' + student_2_id + '"]');
    student_1_assignments_checkboxes = $('.js-score-checkbox[data-student-' + student_1_id + '-score-id]');
    student_2_assignments_checkboxes = $('.js-score-checkbox[data-student-' + student_2_id + '-score-id]');
    student_1_assignment_rows = $('tr[data-score-student-row="' + student_1_id + '"]');
    student_2_assignment_rows = $('tr[data-score-student-row="' + student_2_id + '"]');
  });

  describe('documents loads', function() {
    it('marks all student checkboxes as checked', function () {
      expect(student_1_checkbox).toHaveAttr('aria-checked');
      expect(student_2_checkbox).toHaveAttr('aria-checked');
    });

    it('marks all assignment checkboxes as checked', function () {
      student_1_assignments_checkboxes.each(function () {
        expect($(this)).toHaveAttr('aria-checked');
      });
      student_2_assignments_checkboxes.each(function () {
        expect($(this)).toHaveAttr('aria-checked');
      });
    });


    it('hides score rows', function () {
      student_1_assignment_rows.each(function () {
        expect($(this)).toHaveClass('u-hidden');
      });
      student_2_assignment_rows.each(function () {
        expect($(this)).toHaveClass('u-hidden');
      });
    });
  });

  describe('when clicking the checkbox in the top header', function() {
    var global_checkbox;

    beforeEach(function () {
      global_checkbox = $('.js-checkbox-all');
      global_checkbox.click();
    });

    it('removes check marks from all checkboxes (assignments nad students)', function() {
      expect(student_1_checkbox).not.toHaveAttr('aria-checked');
      expect(student_2_checkbox).not.toHaveAttr('aria-checked');
      student_1_assignments_checkboxes.each(function () {
        expect($(this)).not.toHaveAttr('aria-checked');
      });
      student_2_assignments_checkboxes.each(function () {
        expect($(this)).not.toHaveAttr('aria-checked');
      });
    });

    describe('when checkboxes are not marked as checked', function() {
      it('marks all checkboxes as checked (assignments nad students)', function () {
        global_checkbox.click();
        expect(student_1_checkbox).toHaveAttr('aria-checked');
        expect(student_2_checkbox).toHaveAttr('aria-checked');
        student_1_assignments_checkboxes.each(function () {
          expect($(this)).toHaveAttr('aria-checked');
        });
        student_2_assignments_checkboxes.each(function () {
          expect($(this)).toHaveAttr('aria-checked');
        });
      });
    });
  });

  describe('when clicking a student checkbox', function() {
    beforeEach(function () {
      student_1_checkbox.click();
    });

    it('removes the checkbox check mark', function () {
      expect(student_1_checkbox).not.toHaveAttr('aria-checked');
    });

    it("removes check marks from the student's assignment checkboxes", function () {
      student_1_assignments_checkboxes.each(function () {
        expect($(this)).not.toHaveAttr('aria-checked');
      });
    });

    it("does not remove the check mark from another students' assignment checkboxes", function () {
      expect(student_2_checkbox).toHaveAttr('aria-checked');
    });

    it("does not remove check marks from another students' assignment checkboxes", function () {
      student_2_assignments_checkboxes.each(function () {
        expect($(this)).toHaveAttr('aria-checked');
      });
    });
  });

  describe("when clicking a student's row", function () {
    beforeEach(function () {
      student_1_name_cell.click();
    });

    it("displays the student's assignments", function () {
      student_1_assignment_rows.each(function () {
        expect($(this)).not.toHaveClass('u-hidden');
      });
    });

    it("does not display other students' assignments", function () {
      student_2_assignment_rows.each(function () {
        expect($(this)).toHaveClass('u-hidden');
      });
    });
  });

  describe('when clicking the "accept late work button"', function () {
    it('displays a submission confirmation dialog', function () {
      expect($(submission_dialog)).toHaveClass('u-hidden');
      $('.js-accept-late-work').click();
      expect($(submission_dialog)).not.toHaveClass('u-hidden');
    });
  });
});
