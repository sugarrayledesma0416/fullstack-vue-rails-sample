describe QuestionBankAssessmentPresenter do
  include Rails.application.routes.url_helpers

  let(:json) do
    File.read(
      File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
    )
  end

  let(:filename) { 'file.csv' }

  let(:course) { create(:course) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson_1) { create(:lesson, unit: unit) }
  let(:lesson_2) { create(:lesson, unit: unit) }

  let(:strand_1) do
    create(:toc_entry, assessment: true, title: 'L1 quizzes')
  end

  let(:concept_1) do
    create_concept_from_strand(strand_1, lesson_1)
  end

  let(:strand_2) do
    create(:toc_entry, assessment: true, title: 'L1 tests')
  end

  let(:concept_2) do
    create_concept_from_strand(strand_2, lesson_1)
  end

  let(:other_lesson_strand) do
    create(:toc_entry, assessment: true, title: 'L2 quizzes')
  end

  let(:other_lesson_concept) do
    create_concept_from_strand(other_lesson_strand, lesson_2)
  end

  # topic 1 will be associated with concept 1 and concept 2
  let(:topic_1) { create(:question_bank_topic) }

  # topic 2 will be associated with concept 2
  let(:topic_2) { create(:question_bank_topic) }

  # topic 3 will be associated with other_lesson_concept
  let(:topic_3) { create(:question_bank_topic) }

  let!(:topic_1_question_bank) do
    create(:question_bank, content_json: json, question_bank_topic: topic_1)
  end

  let!(:topic_2_question_bank) do
    create(:question_bank, content_json: json, question_bank_topic: topic_2)
  end

  let(:presenter) do
    described_class.new(
      lesson_id: lesson_1.id,
      program_id: program.id
    )
  end

  def create_concept_from_strand(strand, lesson)
    create(
      :concept,
      assessment: strand.assessment?,
      id: strand.location,
      lesson: lesson,
      name: strand.title
    )
  end

  def create_question_bank_revision(question_bank_id, status)
    QuestionBankRevision.create!(
      activity_id: question_bank_id,
      content_json: json,
      upload_filename: filename
    ).update!(status: status)
  end

  before do
    lesson_1.toc_entries = [
      strand_1,
      strand_2
    ]
    lesson_1.save!

    lesson_2.toc_entries = [other_lesson_strand]
    lesson_2.save!

    create(
      :question_bank_topics_concept,
      concept: concept_1,
      question_bank_topic: topic_1
    )

    create(
      :question_bank_topics_concept,
      concept: concept_2,
      question_bank_topic: topic_1
    )

    create(
      :question_bank_topics_concept,
      concept: concept_2,
      question_bank_topic: topic_2
    )

    create(
      :question_bank_topics_concept,
      concept: other_lesson_concept,
      question_bank_topic: topic_3
    )

    create_question_bank_revision(topic_1_question_bank.id, 'archived')
    create_question_bank_revision(topic_1_question_bank.id, 'rejected')
    create_question_bank_revision(topic_1_question_bank.id, 'live')
    create_question_bank_revision(topic_2_question_bank.id, 'archived')
    create_question_bank_revision(topic_2_question_bank.id, 'live')

    # question bank in topic 2 with no live revision
    create(:question_bank, content_json: json, question_bank_topic: topic_2)
    create(:question_bank, content_json: json, question_bank_topic: topic_3)
  end

  describe '#activity_data' do
    def activity_list
      presenter.activity_data.flat_map do |strand|
        strand[:activities].map { |activity| activity.slice(:id, :title) }
      end
    end

    def activity_ids
      activity_list.map { |entry| entry[:id] }
    end

    it 'returns vhl-created activities for the specified lesson, only if ' \
       'they are in an assessment strand' do
      expect(activity_list).to contain_exactly(
        { id: topic_1_question_bank.id, title: topic_1_question_bank.title },
        { id: topic_2_question_bank.id, title: topic_2_question_bank.title }
      )
    end

    it 'sorts the activities by concept rank, then alphabetically' do
      concept_1.update!(rank: 2)
      concept_2.update!(rank: 1)
      other_strand_1_activity = create(
        :activity,
        concept: concept_1,
        lesson: lesson_1,
        toc_location: strand_1.location,
        toc_location_rank: 1
      )

      expect(activity_ids).to eq(
        [topic_2_question_bank.id, topic_1_question_bank.id]
      )
    end

    it 'returns the activities grouped by strand, including strand id and ' \
       'strand name for each group' do
      expect(presenter.activity_data).to contain_exactly(
        hash_including(
          id: concept_1.id,
          name: concept_1.name,
          activities: match_array(
            [hash_including(id: topic_1_question_bank.id, title: topic_1_question_bank.title)]
          )
        ),
        hash_including(
          id: concept_2.id,
          name: concept_2.name,
          activities: match_array(
            [hash_including(id: topic_2_question_bank.id, title: topic_2_question_bank.title)]
          )
        )
      )
    end

    it 'returns a url property for each activity with the mix and match ' \
       'assessment path for that activity' do
    end
  end
end
