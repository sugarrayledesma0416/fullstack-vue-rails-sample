module DemoCourseBuild
  describe CourseDataCopier do
    let(:program) { build_stubbed(:program) }
    let(:model_demo_instructor) { build_stubbed(:instructor) }

    let(:model_demo_course) { create(:course, owner: model_demo_instructor,
                                              program: program,
                                              created_at: 5.days.ago,
                                              updated_at: 5.days.ago) }
    let(:model_demo_section) { create(:section, course: model_demo_course) }

    let!(:model_category_1) { create(:category, weighting_percent: 45,
                                                course: model_demo_course) }
    let!(:model_category_2) { create(:category, weighting_percent: 55,
                                                course: model_demo_course) }

    let(:demo_instructor) { build_stubbed(:instructor) }

    let(:demo_course) { create(:course, name: 'Trial Course',
                                        start_date: 8.days.ago.to_date,
                                        end_date: 92.days.from_now.to_date,
                                        program: program,
                                        owner: demo_instructor) }
    let(:demo_section) { create(:section, course: demo_course) }

    let(:demo_student_1) { create(:student, username: 'demo_student_1') }
    let(:demo_student_2) { create(:student, username: 'demo_student_2') }

    let(:data_copier) { described_class.new(model_course: model_demo_course,
                                            demo_course: demo_course,
                                            demo_section: demo_section,
                                            students: [demo_student_1, demo_student_2]) }

    describe '#copy_course_settings' do
      before do
        model_demo_course.sections = [model_demo_section]
        model_demo_course.categories = [model_category_1, model_category_2]
        model_demo_section.students = [demo_student_1, demo_student_2]
        demo_course.sections = [demo_section]
        allow(Maestro::CourseLicense).to receive(:copy).and_return(true)
      end

      it 'tells Maestro::CourseLicense to copy from the model demo course to the current course' do
        expect(Maestro::CourseLicense).to receive(:copy)
          .with(model_demo_course.guid, demo_course.guid)
          .and_return(true)

        data_copier.copy_course_settings
      end

      it 'raises an error if the Maestro::CourseLicense copy fails' do
        allow(Maestro::CourseLicense).to receive(:copy).and_return(false)

        expected_error = /Failed to copy.*from.*#{model_demo_course.id} to.*#{demo_course.id}/
        expect{ data_copier.copy_course_settings }.to raise_error expected_error
      end

      it 'copies categories from the model demo course' do
        data_copier.copy_course_settings

        model_demo_course.categories.each_with_index do |model_category, index|
          new_cat = demo_course.categories[index]
          new_cat.attributes.keys.each do |attribute|
            attributes_to_skip = [:id, :course_id, :created_at, :updated_at]
            unless attributes_to_skip.include?(attribute.to_sym)
              expect(new_cat[attribute]).to eql model_category[attribute]
            end
          end
        end
      end

      it 'copies assignments from the model course to the new course adjusing the due dates' do
        offset = 20
        model_due_date = model_demo_course.start_date + offset.days
        create(
          :assignment,
          due_date: model_due_date,
          category: model_category_1,
          section: model_demo_section
        )
        create(
          :assignment,
          due_date: model_due_date,
          category: model_category_2,
          section: model_demo_section
        )

        data_copier.copy_course_settings

        new_assignment_1 = demo_course.categories.first.assignments.first
        expect(new_assignment_1.category.name).to eql model_category_1.name
        expect(new_assignment_1.due_date).to eql demo_course.start_date + offset.days

        new_assignment_2 = demo_course.categories.last.assignments.first
        expect(new_assignment_2.category.name).to eql model_category_2.name
        expect(new_assignment_2.due_date).to eql demo_course.start_date + offset.days
      end

      it 'ignores assignments for external activities' do
        offset = 20
        model_due_date = model_demo_course.start_date + offset.days
        assignment = create(
          :assignment,
          due_date: model_due_date,
          category: model_category_1,
          section: model_demo_section
        )
        external_assignment = create(
          :assignment,
          due_date: model_due_date,
          category: model_category_1,
          section: model_demo_section
        )
        # bypass validations to create a deprecated ExternalActivity
        # assignment.
        external_assignment.update_column(
          :assignable_type,
          'ExternalActivity'
        )

        data_copier.copy_course_settings

        results = demo_course.categories.first.assignments
        expect(results.map(&:assignable_id)).to eq([assignment.assignable_id])
      end
    end

    describe '#create_cloned_attempts' do
      let(:model_student_1) { create(:student, username: 'model_student_1') }
      let(:model_student_2) { create(:student, username: 'model_student_2') }

      it 'finds model students for each demo course student' do
        model_data = double(ModelData, model_section: model_demo_section,
                                       model_students: [model_student_1, model_student_2])
        allow(data_copier).to receive(:model_data).and_return(model_data)

        create(:attempt, section: model_demo_section, user: model_student_1)
        create(:attempt, section: model_demo_section, user: model_student_2)

        data_copier.create_cloned_attempts([demo_student_1, demo_student_2])

        expect(demo_student_1.attempts.first.activity_id).to eql model_student_1.attempts.first.activity_id
        expect(demo_student_2.attempts.first.activity_id).to eql model_student_2.attempts.first.activity_id
      end

      it 'does not copy attempts from sections other than the model section' do
        model_data = double(ModelData, model_section: model_demo_section,
                                       model_students: [model_student_1])
        allow(data_copier).to receive(:model_data).and_return(model_data)

        model_demo_section.students = [model_student_1]
        model_section_attempt = create(:attempt, section: model_demo_section, user: model_student_1)
        other_section_attempt = create(:attempt, section: create(:section), user: model_student_1)

        data_copier.create_cloned_attempts([demo_student_1])

        cloned_attempt_activity_ids = demo_student_1.attempts.map(&:activity_id)
        expect(cloned_attempt_activity_ids).to include model_section_attempt.activity_id
        expect(cloned_attempt_activity_ids).not_to include other_section_attempt.activity_id
      end

      it 're-uses model students if there are more demo course students than model students' do
        model_data = double(ModelData, model_section: model_demo_section,
                                       model_students: [model_student_1])
        allow(data_copier).to receive(:model_data).and_return(model_data)

        model_demo_section.students = [model_student_1]
        create(:attempt, section: model_demo_section, user: model_student_1)

        data_copier.create_cloned_attempts([demo_student_1, demo_student_2])

        expect(demo_student_1.attempts.first.activity_id).to eql model_student_1.attempts.first.activity_id
        expect(demo_student_2.attempts.first.activity_id).to eql model_student_1.attempts.first.activity_id
      end
    end

    describe '#create_scores_and_grades' do
      let(:activity) { create(:activity) }
      let(:attempt) { create(:attempt, :activity => activity, :user => student) }
      let(:student) { create(:fake_student) }
      let(:real_student) { build_stubbed(:student) }
      let(:category) { create(:category, :weighting_percent => 100) }
      let!(:submission) { ::Gradebook::Submission.new(student, nil, activity) }
      let!(:real_student_submission) { ::Gradebook::Submission.new(real_student, nil, activity)}

      let(:data_copier) { described_class.new(model_course: model_demo_course,
                                              demo_course: demo_course,
                                              demo_section: demo_section,
                                              students: [demo_student_1, demo_student_2]) }
      before do
        allow(::Gradebook::Submission).to receive(:new).and_return(submission)
        allow(demo_section).to receive(:attempts).and_return([attempt])
        demo_course.categories = [category]
      end

      it 'creates scores for each attempt' do
        expect(submission).to receive(:create_demo_score)

        data_copier.create_scores_and_grades
      end

      context 'given attempts for assigned activities' do
        before do
          @assignment = create(:assignment, :section => demo_section, :assignable => activity,
                                             :due_date => (demo_course.start_date + 30.days).to_date,
                                             :category => category)
        end

        # we randomly pick whether submissions should be late or on time, but if we stub the randomness
        # we can test the desired behaviour for both cases
        context 'when scores should be late' do
          before do
            allow(data_copier).to receive(:should_be_late?).and_return(true)
          end

          it 'creates scores with submitted at dates between the assignment due date and course end date' do
            day_range = (demo_course.end_date - @assignment.due_date)
            expect(data_copier).to receive(:rand_offset).with(day_range).and_return( 5.days )

            expect(submission).to receive(:create_demo_score).with(attempt, @assignment.due_date_time + 5.days)

            data_copier.create_scores_and_grades
          end
        end

        context 'when scores should be on time' do
          before do
            allow(data_copier).to receive(:should_be_late?).and_return(false)
          end

          it 'creates scores with submitted at dates between the course start date and assignment due date' do
            day_range = (@assignment.due_date - demo_course.start_date )
            expect(data_copier).to receive(:rand_offset).with(day_range).and_return( 8.days )

            expect(submission).to receive(:create_demo_score).with(attempt, @assignment.due_date_time - 8.days)

            data_copier.create_scores_and_grades
          end
        end

      end

      context 'when there are attempts for activities that are not assigned' do
        it 'creates scores with submitted at dates between the course start date and course end date' do
          day_range = (demo_course.end_date - demo_course.start_date)
          expect(data_copier).to receive(:rand_offset).with(day_range).and_return( 7.days )

          expect(submission).to receive(:create_demo_score).with(attempt, demo_course.start_date + 7.days)

          data_copier.create_scores_and_grades
        end
      end

      context "when student is a fake student" do
        it "does add an error about using non fake students" do
          allow(submission).to receive(:create_demo_score)
          data_copier.create_scores_and_grades
          expect(data_copier.errors.full_messages).not_to include "using a non fake student on a demo course"
        end
      end

      context "when student is a real student" do
        it "adds an error to the demo course" do
          allow(::Gradebook::Submission).to receive(:new).and_return(real_student_submission)
          allow(attempt).to receive(:user).and_return(real_student)
          allow(real_student_submission).to receive(:create_demo_score)
          data_copier.create_scores_and_grades
          expect(data_copier.errors.full_messages).to include "using a non fake student on a demo course"
        end
      end
    end
  end
end
