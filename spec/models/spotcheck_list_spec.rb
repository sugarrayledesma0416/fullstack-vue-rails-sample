# This class simulates the row format retrieved from the
# GradebookEngine::GradebookAPI query. The results include an attribute
# that isn't found on a normal ScoreAction, so an instance
# double would raise errors trying to use those results. Instantiating
# real ScoreAction instances would have the same problem. This test record
# class exposes the same methods as the records returned by the query, so
# it should allow the maximum amount of code to be exercised
# without having to stub methods on individual instances.
class FakeGradebookEngineSpotcheckRecord
  attr_accessor :args

  def initialize(args)
    @args = { seconds_spent: 1 }.merge(args)
  end

  %i[seconds_spent user_id].each do |method|
    define_method method do
      args[method]
    end
  end
end

describe SpotcheckList do
  let(:score_class) { FakeGradebookEngineSpotcheckRecord }
  let(:gradebook_api) { GradebookEngine::GradebookAPI }
  let(:user) { create(:user) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:student_3) { create(:student) }
  let(:student_4) { create(:student) }
  let(:activity) { create(:activity) }
  let(:activity_id) { activity.id }
  let(:section_id) { create(:section).id }

  let(:default_args) do
    {
      activity_id: activity_id,
      section_ids: [section_id],
      students: [student_1],
      unassigned: false
    }
  end

  def create_spotcheck_list(args = {})
    described_class.new(**default_args.merge(args))
  end

  before do
    create(:active_enrollment, section_id: section_id, user: student_1)
    create(:active_enrollment, section_id: section_id, user: student_2)
    create(:active_enrollment, section_id: section_id, user: student_3)
    create(:completed_enrollment, section_id: section_id, user: student_4)
    create(:assignment, assignable: activity, section_id: section_id)
  end

  describe '#manual_student_list' do
    it 'returns an empty array when there are no scores for the specified ' \
       'students' do
      allow(gradebook_api).to receive(:spotcheck_results)
        .and_return([score_class.new(user_id: student_2.id)])
      spotcheck_list = create_spotcheck_list(students: [student_1])
      expect(spotcheck_list.manual_student_list).to eq([])
    end

    context 'when there are scores for the specified students,' do
      it 'does not return students whose scores have no time spent' do
        allow(gradebook_api).to receive(:spotcheck_results)
          .and_return(
            [score_class.new(seconds_spent: 0, user_id: student_1.id)]
          )
        spotcheck_list = create_spotcheck_list(students: [student_1])
        expect(spotcheck_list.manual_student_list).to eq([])
      end
    end

    context 'when some activities are individually-assignable,' do
      before do
        Assignment.find_by(assignable_id: activity.id).update!(
          individually_assignable: true
        )
        IndividualAssignment.create!(
          activity_id: activity.id,
          section_id: section_id,
          user_id: student_1.id
        )
        allow(gradebook_api).to receive(:spotcheck_results).and_return(
          [
            score_class.new(seconds_spent: 1, user_id: student_1.id),
            score_class.new(seconds_spent: 1, user_id: student_2.id)
          ]
        )
      end

      context 'with an assigned work grading set,' do
        it 'filters out students for whom the activity is not ' \
           'individually-assigned' do
          spotcheck_list = create_spotcheck_list(
            students: [student_1, student_2],
            unassigned: false
          )

          expect(spotcheck_list.manual_student_list).to eq([student_1])
        end
      end

      context 'with an unassigned work grading set,' do
        it 'includes only students for whom the activity is not ' \
           'individually-assigned' do
          spotcheck_list = create_spotcheck_list(
            students: [student_1, student_2],
            unassigned: true
          )

          expect(spotcheck_list.manual_student_list).to eq([student_2])
        end
      end
    end
  end

  describe '#outlier_student_list' do
    it 'returns students, sorted greatest to least, by how much the seconds_spent' \
       'attribute of their score differs from the average' do
      scores = [
        score_class.new(seconds_spent: 30, user_id: student_1.id), # avg +3
        score_class.new(seconds_spent: 50, user_id: student_2.id), # avg +17
        score_class.new(seconds_spent: 20, user_id: student_3.id)  # avg -13
      ]
      allow(gradebook_api).to receive(:spotcheck_results)
        .and_return(scores)
      students = [student_1, student_2, student_3]
      spotcheck_list = create_spotcheck_list(students: students)
      expect(spotcheck_list.outlier_student_list).to eq(
        [student_2, student_3, student_1]
      )
    end
  end

  describe '#random_student_list' do
    let(:student_5) { create(:student) }
    let(:students) { [student_5, student_3, student_1, student_2, student_4] }
    let(:scores) do
      [
        score_class.new(user_id: student_1.id),
        score_class.new(user_id: student_2.id),
        score_class.new(user_id: student_3.id),
        score_class.new(user_id: student_4.id),
        score_class.new(user_id: student_5.id)
      ]
    end

    before do
      create(:active_enrollment, section_id: section_id, user: student_5)
      allow(student_1).to receive(:spotcheck_count).and_return(1)
      allow(student_2).to receive(:spotcheck_count).and_return(0)
      allow(student_3).to receive(:spotcheck_count).and_return(2)
      allow(student_4).to receive(:spotcheck_count).and_return(1)
      allow(student_5).to receive(:spotcheck_count).and_return(1)
      allow(gradebook_api).to receive(:spotcheck_results)
        .and_return(scores)
    end

    it 'returns students with the lowest number of past spotchecks first' do
      spotcheck_list = create_spotcheck_list(students: students)
      results = spotcheck_list.random_student_list
      expect([results.first, results.last]).to eq([student_2, student_3])
    end

    it 'groups students with a tied number of past spotchecks together' do
      spotcheck_list = create_spotcheck_list(students: students)
      results = spotcheck_list.random_student_list
      expect(results[1..3]).to match_array([student_1, student_4, student_5])
    end
  end

  describe '#score_for' do
    it 'queries the GradebookAPI only once to get all the scores ' \
       'for the activity, sections, and students specified on initialize' do
      allow(gradebook_api).to receive(:spotcheck_results)
        .and_return([])
      spotcheck_list = create_spotcheck_list(students: [student_1, student_2])
      spotcheck_list.score_for(student_1)
      # Verify that the GradebookAPI query happens only once for all students
      spotcheck_list.score_for(student_2)
      expect(gradebook_api).to have_received(:spotcheck_results)
        .once.with(
          activity_id: activity_id,
          section_ids: [section_id],
          user_ids: [student_1.id, student_2.id]
        )
    end

    it 'returns the score for the specified student' do
      student_1_score = score_class.new(user_id: student_1.id)
      scores = [
        student_1_score,
        score_class.new(user_id: student_2.id)
      ]
      allow(gradebook_api).to receive(:spotcheck_results)
        .and_return(scores)
      spotcheck_list = create_spotcheck_list(students: [student_1, student_2])
      expect(spotcheck_list.score_for(student_1)).to eq(student_1_score)
    end
  end

  describe '#grade_for' do
    it 'queries the GradebookAPI only once to get all the top-level grades ' \
       'for the sections specified on initialize' do
      allow(gradebook_api).to receive(:top_level_grades)
        .and_return([])
      spotcheck_list = create_spotcheck_list(students: [student_1, student_2])
      spotcheck_list.grade_for(student_1)
      # Verify that the GradebookAPI query happens only once for all students
      spotcheck_list.grade_for(student_2)
      expect(gradebook_api).to have_received(:top_level_grades)
        .once.with(section_ids: [section_id])
    end

    it 'returns nil if there is no grade for the specified student' do
      allow(gradebook_api).to receive(:top_level_grades)
        .and_return([])
      spotcheck_list = create_spotcheck_list(students: [student_1, student_2])
      expect(spotcheck_list.grade_for(student_1)).to be_nil
    end

    it 'returns the grade for the specified student' do
      student_1_ratio = 0.5
      student_1_grade = instance_double(
        GradebookEngine::Grade,
        net_ratio: student_1_ratio,
        user: student_1
      )
      student_2_grade = instance_double(
        GradebookEngine::Grade,
        net_ratio: 0.1,
        user: student_2
      )
      allow(gradebook_api).to receive(:top_level_grades)
        .and_return([student_1_grade, student_2_grade])
      spotcheck_list = create_spotcheck_list(students: [student_1, student_2])
      expect(spotcheck_list.grade_for(student_1)).to eq(student_1_ratio)
    end
  end

  describe '#time_spent_for' do
    it 'returns the time spent of the attempt for the specified student' do
      scores = [
        score_class.new(seconds_spent: 60, user_id: student_1.id),
        score_class.new(seconds_spent: 120, user_id: student_2.id)
      ]
      allow(gradebook_api).to receive(:spotcheck_results)
        .and_return(scores)
      students = [student_1, student_2]
      spotcheck_list = create_spotcheck_list(students: students)
      results = students.map do |student|
        spotcheck_list.time_spent_for(student)
      end
      expect(results).to eq([60, 120])
    end
  end

  describe '#submission_for' do
    let(:submission_length_by_attempt_id) { {} }

    def create_attempt(args = {})
      length = args.delete(:length)
      attrs = {
        activity_id: activity_id,
        section_id: section_id,
        status_code: AttemptStatus::CODE_COMPLETED,
        user_id: student_1.id
      }
      attempt = create(:attempt, attrs.merge(args))
      submission_length_by_attempt_id[attempt.id] = length
    end

    before do
      student_1_score = score_class.new(user_id: student_1.id)
      scores = [
        student_1_score,
        score_class.new(user_id: student_2.id)
      ]
      allow(gradebook_api).to receive(:spotcheck_results)
        .and_return(scores)
      # rubocop:disable RSpec/AnyInstance
      # This is the only way to test submission length short of setting up
      # activities with content objects and stubbing
      # SubmissionClient::Submission to return serialized responses that can
      # then be parsed by the content object into MAE Results instances.
      allow_any_instance_of(Attempt).to receive(:submission_length) do |attempt|
        submission_length_by_attempt_id[attempt.id]
      end
      # rubocop:enable RSpec/AnyInstance
    end

    it 'returns nil when there are no attempts' do
      spotcheck_list = create_spotcheck_list(
        activity_id: activity_id,
        students: [student_1, student_2]
      )
      expect(spotcheck_list.submission_length_for(student_1)).to be_nil
    end

    it 'returns nil when there are no attempts that are submitted or ' \
       'completed' do
      students = [student_1, student_2, student_3, student_4]
      create_attempt(
        length: 1, status_code: AttemptStatus::CODE_UNOPENED, user_id: student_1.id
      )
      create_attempt(
        length: 2, status_code: AttemptStatus::CODE_OPENED, user_id: student_2.id
      )
      create_attempt(
        length: 3, status_code: AttemptStatus::CODE_RESET, user_id: student_3.id
      )
      create_attempt(
        length: 4, status_code: AttemptStatus::CODE_STARTED, user_id: student_4.id
      )
      spotcheck_list = create_spotcheck_list(students: students)
      results = students.map do |student|
        spotcheck_list.submission_length_for(student)
      end
      expect(results).to eq([nil, nil, nil, nil])
    end

    it 'returns the submission_length of the attempt for the specified ' \
       'student, for the activity and sections specified on initialize' do
      # By default user is student_1, status code is CODE_COMPLETED.
      # Validate that both submitted and completed attempts are checked.
      create_attempt(length: 1, status_code: AttemptStatus::CODE_SUBMITTED)
      # Completed attempt in non-specified section.
      create_attempt(length: 2, section_id: create(:section).id)
      # Completed attempt for different student.
      create_attempt(length: 3, user_id: student_2.id)
      # Completed attempt for non-specified activity.
      create_attempt(length: 4, activity_id: create(:activity).id)

      students = [student_1, student_2]
      spotcheck_list = create_spotcheck_list(students: students)
      results = students.map do |student|
        spotcheck_list.submission_length_for(student)
      end
      expect(results).to eq([1, 3])
    end
  end
end
