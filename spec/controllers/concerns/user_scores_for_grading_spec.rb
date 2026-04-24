describe UserScoresForGrading do
  let(:user) { create(:student) }
  let(:attempt) { create(:attempt) }
  let(:params) { {} }
  let(:recording_configuration_instance) { {} }
  let(:activity) { instance_double(Activity) }
  let(:feedback) { instance_double(GradingFeedback) }
  let(:score_controls_view_manager) { instance_double(ScoreControlsViewManager) }

  shared_examples_for 'chat type comment boxes for rubric grading' do
    it 'returns comment markup for student non-practicing users' do
      scores = described_class.new(presenter, params, recording_configuration_instance)
      expect(scores.comment_boxes).to eq(%w[user_markup partner_1_markup])
    end

    it 'does not return comment markup for non gradable users' do
      allow(presenter).to receive(:gradeable?).with(user).and_return(true)
      allow(presenter).to receive(:gradeable?).with(partner_1).and_return(false)
      scores = described_class.new(presenter, params, recording_configuration_instance)
      expect(scores.comment_boxes).to eq(%w[user_markup])
    end

    it 'does not return comment markup for instructor and practicing users' do
      # this setup for teammates matches what happens with a group chat with 3 users.
      allow(presenter).to receive(:teammates).and_return([instructor_partner, partner_1])
      allow(presenter).to receive(:partner_is_practicing?).with(user, user).and_return(false)
      allow(presenter).to receive(:partner_is_practicing?).with(partner_1, user).and_return(true)
      allow(ActionController::Base)
        .to(receive(:render))
        .with(
          partial_string,
          hash_including(
            locals: hash_including(
              # just need to test that the correct user was passed to render.
              comment_box_class: "js-comment-for-foobar-student-#{user.id}"
            )
          )
        )
        .and_return('user_markup')
      scores = described_class.new(presenter, params, recording_configuration_instance)
      expect(scores.comment_boxes).to eq(%w[user_markup])
    end
  end

  shared_examples_for 'a #score_list' do
    it 'returns score data' do
      scores = described_class.new(presenter, params, recording_configuration_instance)
      expect(scores.score_list).to eq(expected_scores)
    end
  end

  before do
    # Setup common to all scenarios
    allow(presenter).to receive(:activity).and_return(activity)
    allow(presenter).to receive(:questions_to_grade).and_return([OpenStruct.new(label: 'foobar')])
    allow(presenter).to receive(:feedback).and_return(feedback)
    allow(presenter).to receive(:response_id)
    allow(presenter).to receive(:rubric_graded?).and_return(true)
    allow(feedback).to receive(:question_feedback).and_return('some feedback')
    allow(ScoreControlsViewManager)
      .to receive(:new).and_return(score_controls_view_manager)
    allow(score_controls_view_manager)
      .to receive(:rubric_criteria_scores).and_return('rubric scores')
    allow(score_controls_view_manager).to receive(:question_points).and_return('')
    allow(score_controls_view_manager).to receive(:score_field).and_return('input name')
  end

  describe '#comment_boxes' do
    let(:partner_1) { create(:student) }
    let(:instructor_partner) { create(:instructor) }
    let(:partial_string) do
      '/instructor/grading_sets/_all_instructor_comments_rubric_grading.html.erb'
    end

    before do
      allow(presenter).to receive(:current_student).and_return(user)
      allow(presenter).to receive(:original_user).and_return(user)
      allow(presenter).to receive(:recording_path).and_return('foo')
      allow(presenter).to receive(:new_recording?)
      allow(presenter).to receive(:gradeable?).and_return(true)
      allow(feedback).to receive(:attempt_for_student).and_return(attempt)
      allow(score_controls_view_manager).to receive(:recording_path)
    end

    describe 'with chat type activities' do
      before do
        allow(activity).to receive(:partner_chat?).and_return(true)
        allow(activity).to receive(:group_chat?).and_return(true)
        # this setup for teammates matches what happens with a partner chat.
        allow(presenter).to receive(:teammates).and_return(User.where(id: partner_1.id))
        allow(presenter).to receive(:partner_is_practicing?).and_return(false)
        allow(ActionController::Base)
          .to(receive(:render))
          .with(
            partial_string,
            hash_including(
              locals: hash_including(
                # just need to test that the correct user was passed to render.
                comment_box_class: "js-comment-for-foobar-student-#{user.id}"
              )
            )
          )
          .and_return('user_markup')
        allow(ActionController::Base)
          .to(receive(:render))
          .with(
            partial_string,
            hash_including(
              locals: hash_including(
                # just need to test that the correct user was passed to render.
                comment_box_class: "js-comment-for-foobar-student-#{partner_1.id}"
              )
            )
          )
          .and_return('partner_1_markup')
      end

      context 'with a StudentByStudentPresenter' do
        let(:presenter) { instance_double(StudentByStudentPresenter) }

        it_behaves_like 'chat type comment boxes for rubric grading'
      end

      context 'with a ReviewWorkPresenter' do
        let(:presenter) { instance_double(ReviewWorkPresenter) }

        it_behaves_like 'chat type comment boxes for rubric grading'
      end
    end

    context 'with non chat type activities' do
      before do
        allow(activity).to receive(:partner_chat?).and_return(false)
        allow(activity).to receive(:group_chat?).and_return(false)
        # this setup for teammates matches what happens with a non chat type activity.
        allow(presenter).to receive(:teammates).and_return([])
        allow(ActionController::Base)
          .to(receive(:render))
          .with(
            partial_string,
            hash_including(
              locals: hash_including(
                # just need to test that the correct user was passed to render.
                comment_box_class: "js-comment-for-foobar-student-#{user.id}"
              )
            )
          )
          .and_return('user_markup')
      end

      context 'with a StudentByStudentPresenter' do
        let(:presenter) { instance_double(StudentByStudentPresenter) }

        it 'returns comment box markup for the user' do
          scores = described_class.new(presenter, params, recording_configuration_instance)
          expect(scores.comment_boxes).to eq(%w[user_markup])
        end
      end

      context 'with a ReviewWorkPresenter' do
        let(:presenter) { instance_double(ReviewWorkPresenter) }

        it 'returns comment box markup for the user' do
          scores = described_class.new(presenter, params, recording_configuration_instance)
          expect(scores.comment_boxes).to eq(%w[user_markup])
        end
      end
    end
  end

  describe '#score_list' do
    context 'with a non-chat type activity' do
      let(:expected_scores) do
        [
          {
            user_id: user.id,
            student_name: user.full_name,
            gradable: true,
            instructor: false,
            practicing: false,
            comment_box_class: ".js-comment-for-foobar-student-#{user.id}",
            attempt_id: attempt.id,
            rubric: 'rubric scores',
            manual: nil,
            input_name: 'input name'
          }
        ]
      end

      before do
        allow(presenter).to receive(:teammates).and_return([])
        allow(presenter).to receive(:gradeable?).and_return(true)
        allow(presenter).to receive(:current_student).and_return(user)
        allow(presenter).to receive(:partner_is_practicing?).and_return(false)
        allow(feedback).to receive(:attempt_for_student).and_return(attempt)
        allow(activity).to receive(:partner_chat?).and_return(false)
        allow(activity).to receive(:group_chat?).and_return(false)
      end

      context 'with a StudentByStudentPresenter' do
        let(:presenter) { instance_double(StudentByStudentPresenter) }

        it_behaves_like 'a #score_list'
      end

      context 'with a ReviewWorkPresenter' do
        let(:presenter) { instance_double(ReviewWorkPresenter) }

        it_behaves_like 'a #score_list'
      end
    end

    context 'with a partner chat type activity' do
      # Cases to test for partner chat activity type:
      # * Two student partners
      #   * neither practicing
      #   * one user practicing
      #   * one user not gradable (happens when student is not in an instructor's gradable sections)
      # * One student, one instructor parter

      let(:partner) { create(:student) }
      let(:instructor_partner) { create(:instructor) }
      let(:teammate_attempt) { create(:attempt) }

      before do
        # Setup common to all chat types
        allow(presenter).to receive(:current_student).and_return(user)
        allow(activity).to receive(:partner_chat?).and_return(true)
        allow(activity).to receive(:group_chat?).and_return(false)
      end

      context 'with two student users, no one practicing & one user not gradable' do
        let(:expected_scores) do
          [
            {
              user_id: user.id,
              student_name: user.full_name,
              gradable: true,
              instructor: false,
              practicing: false,
              comment_box_class: ".js-comment-for-foobar-student-#{user.id}",
              attempt_id: attempt.id,
              rubric: 'rubric scores',
              manual: nil,
              input_name: 'input name'
            },
            {
              user_id: partner.id,
              student_name: partner.full_name,
              gradable: false,
              instructor: false,
              practicing: false,
              comment_box_class: nil,
              attempt_id: attempt.id,
              rubric: 'rubric scores',
              manual: nil,
              input_name: 'input name'
            }
          ]
        end

        before do
          allow(presenter).to receive(:teammates).and_return(User.where(id: partner.id))
          allow(presenter).to receive(:gradeable?).and_return(true, false)
          allow(presenter).to receive(:original_user).and_return(user)
          allow(presenter).to receive(:partner_is_practicing?).and_return(false)
          allow(feedback).to receive(:attempt_for_student).with(user).and_return(attempt)
          allow(feedback).to receive(:attempt_for_student).with(partner).and_return(attempt)
        end

        context 'with a StudentByStudentPresenter' do
          let(:presenter) { instance_double(StudentByStudentPresenter) }

          it 'returns score data' do
            scores = described_class.new(presenter, params, recording_configuration_instance)
            expect(scores.score_list).to eq(expected_scores)
          end
        end

        context 'with a ReviewWorkPresenter' do
          let(:presenter) { instance_double(ReviewWorkPresenter) }

          it 'returns score data' do
            scores = described_class.new(presenter, params, recording_configuration_instance)
            expect(scores.score_list).to eq(expected_scores)
          end
        end
      end

      context 'with two student users, one is practicing' do
        let(:expected_scores) do
          [
            {
              user_id: user.id,
              student_name: user.full_name,
              gradable: true,
              instructor: false,
              practicing: true,
              comment_box_class: nil,
              attempt_id: attempt.id,
              rubric: 'rubric scores',
              manual: nil,
              input_name: 'input name'
            },
            {
              user_id: partner.id,
              student_name: partner.full_name,
              gradable: true,
              instructor: false,
              practicing: false,
              comment_box_class: ".js-comment-for-foobar-student-#{partner.id}",
              attempt_id: attempt.id,
              rubric: 'rubric scores',
              manual: nil,
              input_name: 'input name'
            }
          ]
        end

        before do
          allow(presenter).to receive(:teammates).and_return(User.where(id: partner.id))
          allow(presenter).to receive(:gradeable?).and_return(true)
          allow(presenter).to receive(:original_user).and_return(user)
          allow(presenter).to receive(:partner_is_practicing?).with(partner, user).and_return(false)
          allow(presenter).to receive(:partner_is_practicing?).with(user, user).and_return(true)
          allow(feedback).to receive(:attempt_for_student).with(user).and_return(attempt)
          allow(feedback).to receive(:attempt_for_student).with(partner).and_return(attempt)
        end

        context 'with a StudentByStudentPresenter' do
          let(:presenter) { instance_double(StudentByStudentPresenter) }

          it 'returns score data' do
            scores = described_class.new(presenter, params, recording_configuration_instance)
            expect(scores.score_list).to eq(expected_scores)
          end
        end

        context 'with a ReviewWorkPresenter' do
          let(:presenter) { instance_double(ReviewWorkPresenter) }

          it 'returns score data' do
            scores = described_class.new(presenter, params, recording_configuration_instance)
            expect(scores.score_list).to eq(expected_scores)
          end
        end
      end

      context 'with one student and one instructor' do
        let(:expected_scores) do
          [
            {
              user_id: user.id,
              student_name: user.full_name,
              gradable: true,
              instructor: false,
              practicing: false,
              comment_box_class: ".js-comment-for-foobar-student-#{user.id}",
              attempt_id: attempt.id,
              rubric: 'rubric scores',
              manual: nil,
              input_name: 'input name'
            },
            {
              user_id: instructor_partner.id,
              student_name: instructor_partner.full_name,
              gradable: nil,
              instructor: true,
              practicing: nil,
              comment_box_class: nil,
              attempt_id: nil,
              rubric: nil,
              manual: nil,
              input_name: nil
            }
          ]
        end

        before do
          allow(presenter).to receive(:teammates).and_return(User.where(id: instructor_partner.id))
          allow(presenter).to receive(:gradeable?).and_return(true)
          allow(presenter).to receive(:original_user).and_return(user)
          allow(presenter)
            .to receive(:partner_is_practicing?).with(instructor_partner, user).and_return(false)
          allow(presenter).to receive(:partner_is_practicing?).with(user, user).and_return(false)
          allow(feedback).to receive(:attempt_for_student).with(user).and_return(attempt)
        end

        context 'with a StudentByStudentPresenter' do
          let(:presenter) { instance_double(StudentByStudentPresenter) }

          it 'returns score data' do
            scores = described_class.new(presenter, params, recording_configuration_instance)
            expect(scores.score_list).to eq(expected_scores)
          end
        end

        context 'with a ReviewWorkPresenter' do
          let(:presenter) { instance_double(ReviewWorkPresenter) }

          it 'returns score data' do
            scores = described_class.new(presenter, params, recording_configuration_instance)
            expect(scores.score_list).to eq(expected_scores)
          end
        end
      end
    end
  end

  context 'with a group chat type activity' do
    # Cases to test for group chat activity type:
    # * Three student users
    #   * no one practicing
    #   * one user practicing
    #   * one user not gradable (happens when student is not in an instructor's gradable sections)
    # * two students, one instructor parter

    let(:partner_1) { create(:student) }
    let(:partner_2) { create(:student) }
    let(:instructor_partner) { create(:instructor) }
    let(:partner_1_attempt) { create(:attempt) }
    let(:partner_2_attempt) { create(:attempt) }

    before do
      # Setup common to all chat types
      allow(presenter).to receive(:current_student).and_return(user)
      allow(activity).to receive(:partner_chat?).and_return(false)
      allow(activity).to receive(:group_chat?).and_return(true)
    end

    context 'with three student users, no one practicing, one not gradable' do
      let(:expected_scores) do
        [
          {
            user_id: user.id,
            student_name: user.full_name,
            gradable: false,
            instructor: false,
            practicing: false,
            comment_box_class: nil,
            attempt_id: attempt.id,
            rubric: 'rubric scores',
            manual: nil,
            input_name: 'input name'
          },
          {
            user_id: partner_1.id,
            student_name: partner_1.full_name,
            gradable: true,
            instructor: false,
            practicing: false,
            comment_box_class: ".js-comment-for-foobar-student-#{partner_1.id}",
            attempt_id: partner_1_attempt.id,
            rubric: 'rubric scores',
            manual: nil,
            input_name: 'input name'
          },
          {
            user_id: partner_2.id,
            student_name: partner_2.full_name,
            gradable: true,
            instructor: false,
            practicing: false,
            comment_box_class: ".js-comment-for-foobar-student-#{partner_2.id}",
            attempt_id: partner_2_attempt.id,
            rubric: 'rubric scores',
            manual: nil,
            input_name: 'input name'
          }
        ]
      end

      before do
        allow(presenter).to receive(:teammates).and_return([partner_1, partner_2])
        allow(presenter).to receive(:gradeable?).and_return(false, true, true)
        allow(presenter).to receive(:original_user).and_return(user)
        allow(presenter).to receive(:partner_is_practicing?).and_return(false)
        allow(feedback)
          .to receive(:attempt_for_student).with(partner_2).and_return(partner_2_attempt)
        allow(feedback)
          .to receive(:attempt_for_student).with(partner_1).and_return(partner_1_attempt)
        allow(feedback).to receive(:attempt_for_student).with(user).and_return(attempt)
      end

      context 'with a StudentByStudentPresenter' do
        let(:presenter) { instance_double(StudentByStudentPresenter) }

        it_behaves_like 'a #score_list'
      end

      context 'with a ReviewWorkPresenter' do
        let(:presenter) { instance_double(ReviewWorkPresenter) }

        it_behaves_like 'a #score_list'
      end
    end

    context 'with three student users, someone is practicing' do
      let(:expected_scores) do
        [
          {
            user_id: user.id,
            student_name: user.full_name,
            gradable: true,
            instructor: false,
            practicing: true,
            comment_box_class: nil,
            attempt_id: attempt.id,
            rubric: 'rubric scores',
            manual: nil,
            input_name: 'input name'
          },
          {
            user_id: partner_1.id,
            student_name: partner_1.full_name,
            gradable: true,
            instructor: false,
            practicing: false,
            comment_box_class: ".js-comment-for-foobar-student-#{partner_1.id}",
            attempt_id: partner_1_attempt.id,
            rubric: 'rubric scores',
            manual: nil,
            input_name: 'input name'
          },
          {
            user_id: partner_2.id,
            student_name: partner_2.full_name,
            gradable: true,
            instructor: false,
            practicing: false,
            comment_box_class: ".js-comment-for-foobar-student-#{partner_2.id}",
            attempt_id: partner_2_attempt.id,
            rubric: 'rubric scores',
            manual: nil,
            input_name: 'input name'
          }
        ]
      end

      before do
        allow(presenter).to receive(:teammates).and_return([partner_1, partner_2])
        allow(presenter).to receive(:original_user).and_return(user)
        allow(presenter).to receive(:gradeable?).and_return(true)
        allow(presenter).to receive(:partner_is_practicing?).and_return(true, false, false)
        allow(feedback)
          .to receive(:attempt_for_student).with(partner_1).and_return(partner_1_attempt)
        allow(feedback)
          .to receive(:attempt_for_student).with(partner_2).and_return(partner_2_attempt)
        allow(feedback)
          .to receive(:attempt_for_student).with(user).and_return(attempt)
      end

      context 'with a StudentByStudentPresenter' do
        let(:presenter) { instance_double(StudentByStudentPresenter) }

        it_behaves_like 'a #score_list'
      end

      context 'with a ReviewWorkPresenter' do
        let(:presenter) { instance_double(ReviewWorkPresenter) }

        it_behaves_like 'a #score_list'
      end
    end

    context 'with one two student users and one instructor' do
      let(:expected_scores) do
        [
          {
            user_id: user.id,
            student_name: user.full_name,
            gradable: true,
            instructor: false,
            practicing: false,
            comment_box_class: ".js-comment-for-foobar-student-#{user.id}",
            attempt_id: attempt.id,
            rubric: 'rubric scores',
            manual: nil,
            input_name: 'input name'
          },
          {
            user_id: partner_1.id,
            student_name: partner_1.full_name,
            gradable: true,
            instructor: false,
            practicing: false,
            comment_box_class: ".js-comment-for-foobar-student-#{partner_1.id}",
            attempt_id: partner_1_attempt.id,
            rubric: 'rubric scores',
            manual: nil,
            input_name: 'input name'
          },
          {
            user_id: instructor_partner.id,
            student_name: instructor_partner.full_name,
            gradable: nil,
            instructor: true,
            practicing: nil,
            comment_box_class: nil,
            attempt_id: nil,
            rubric: nil,
            manual: nil,
            input_name: nil
          }
        ]
      end

      before do
        allow(presenter).to receive(:teammates).and_return([partner_1, instructor_partner])
        allow(presenter).to receive(:original_user).and_return(user)
        allow(presenter).to receive(:gradeable?).and_return(true)
        allow(presenter).to receive(:partner_is_practicing?).and_return(false)
        allow(feedback)
          .to receive(:attempt_for_student).with(partner_1).and_return(partner_1_attempt)
        allow(feedback).to receive(:attempt_for_student).with(user).and_return(attempt)
      end

      context 'with a StudentByStudentPresenter' do
        let(:presenter) { instance_double(StudentByStudentPresenter) }

        it_behaves_like 'a #score_list'
      end

      context 'with a ReviewWorkPresenter' do
        let(:presenter) { instance_double(ReviewWorkPresenter) }

        it_behaves_like 'a #score_list'
      end
    end
  end
end
