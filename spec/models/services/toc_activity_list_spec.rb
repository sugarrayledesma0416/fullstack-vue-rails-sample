describe Services::TocActivityList do
  let(:program) { create(:program_with_toc_entries) }
  let(:school) { create(:school) }
  let(:course) { create(:course_with_section, program:, school:) }
  let(:instructor) { create(:instructor) }

  RSpec.shared_examples 'with current_user param' do |class_method_to_call, method_param|
    let(:section_owner) { course.owner }
    let(:instructor_activity) do
      create(:activity, lesson:, instructor_revision_id: 1, instructor_id: section_owner.id)
    end
    let!(:section) do
      section = course.sections.first
      section.update!(instructor: section_owner)
      section.section_instructors.create!(
        instructor: section_owner,
        role: SectionInstructor::INSTRUCTOR_ROLE
      )
      section
    end
    let(:other_section) do
      other_section = course.sections.create!(name: 'other section', instructor: course.owner)
      other_section.section_instructors.create!(
        instructor: other_section.instructor,
        role: SectionInstructor::INSTRUCTOR_ROLE
      )
      other_section
    end
    let(:co_instructor_activities) do
      create_list(:instructor, 3).map.with_index do |co_instructor, index|
        if index % 2 == 0
          section.section_instructors.create!(
            instructor: co_instructor,
            role: SectionInstructor::COINSTRUCTOR_ROLE
          )
        else
          other_section.section_instructors.create!(
            instructor: co_instructor,
            role: SectionInstructor::COINSTRUCTOR_ROLE
          )
        end
        create(
          :activity,
          lesson:,
          instructor_revision_id: 1,
          instructor_id: co_instructor.id
        )
      end
    end

    context 'with a student' do
      let(:user) { create(:student) }

      it 'returns visible instructor created activities for the given program, ' \
         'with a student as the current user' do
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: course.sections,
          current_user: user
        )

        expect(results).to eq [instructor_activity.id]
      end

      it 'returns instructor created activities that are not in the course library if ' \
         'they are assigned' do
        create(:assignment, assignable: instructor_activity, section:)
        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: [section],
          current_user: user
        )

        expect(results).to eq [instructor_activity.id]
      end

      it 'does not return instructor created activities that are not in the course library if ' \
         'they are not assigned' do
        instructor_activity
        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: [section],
          current_user: user
        )

        expect(results).to eq []
      end

      it 'returns activities from all instructors of the section, if they are assigned' do
        co_instructor_activity = co_instructor_activities.first
        co_instructor = Instructor.find(co_instructor_activity.instructor_id)
        section.section_instructors.where(
          instructor: co_instructor,
          role: SectionInstructor::COINSTRUCTOR_ROLE
        ).first_or_create
        create(:assignment, assignable: co_instructor_activity, section:)
        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: [section],
          current_user: user
        )

        expect(results).to match_array [co_instructor_activity.id]
      end

      it 'does not return activities from co-instructors of other sections in the same course' do
        co_instructor = create(:instructor)
        other_section.section_instructors.create!(
          instructor: co_instructor,
          role: SectionInstructor::COINSTRUCTOR_ROLE
        )
        co_instructor_activity = create(
          :activity,
          lesson:, instructor_revision_id: 1,
          instructor_id: co_instructor.id
        )
        create(:assignment, assignable: co_instructor_activity, section: other_section)
        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: [section],
          current_user: user
        )

        expect(results).to eq []
      end
    end

    context 'with an instructor' do
      let(:user) { course.owner }

      it 'returns visible instructor created activities for the given program, ' \
         'with an instructor as the current user' do
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: course.sections,
          current_user: user
        )

        expect(results).to include instructor_activity.id
      end

      it 'returns instructor created activities that are not in the course library if ' \
         'they are assigned' do
        create(:assignment, assignable: instructor_activity, section:)
        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: [section],
          current_user: user
        )

        expect(results).to include instructor_activity.id
      end

      it 'returns instructor created activities that are not in the course library even if ' \
         'they are not assigned' do
        instructor_activity
        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: [section],
          current_user: user
        )

        expect(results).to include instructor_activity.id
      end

      it 'returns activities from all instructors of the section, if it is the section owner' do
        co_instructor_activities
        instructor_activity
        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: course.sections,
          current_user: user
        )

        expect(results).to match_array( co_instructor_activities.pluck(:id) + [instructor_activity.id] )
      end

      it 'returns activities from all instructors of the section, if it is an institution admin' do
        co_instructor_activities
        instructor_activity
        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: course.sections,
          current_user: create(:institution_admin)
        )

        expect(results).to match_array( co_instructor_activities.pluck(:id) + [instructor_activity.id] )
      end

      it 'returns only activities from the section owner, co-instructors and its own ' \
         'if it is a co-instructor' do
        co_instructor_activities
        co_instructor = section.section_instructors.where(
          role: SectionInstructor::COINSTRUCTOR_ROLE
        ).first
        instructor_activity
        results = described_class.public_send(
          class_method_to_call,
          eval(method_param),
          sections: course.sections,
          current_user: co_instructor.instructor
        )

        section_instructor_activity_ids = Activity.where(
          instructor_id: section.instructors.pluck(:id)
        ).pluck(:id)
        expect(results).to match_array section_instructor_activity_ids
        other_section_instructor_activities = Activity.where(
          instructor_id: other_section.instructors.pluck(:id)
        )
        expect(other_section_instructor_activities).not_to be_empty
      end
    end
  end

  describe '.all_for_program' do
    let(:other_program) { create(:program_with_toc_entries) }
    let(:lesson) { program.lessons.first }

    context 'with a section,' do
      include_examples 'with current_user param', 'all_for_program', 'program'

      it 'returns visible activities for the given program as visible' do
        visible_activity = create(:activity, lesson:)

        results = described_class.all_for_program(program, sections: course.sections)

        expect(results).to eq [visible_activity.id]
      end

      it 'returns hidden activities for the given program as hidden' do
        hidden_activity = create(:activity, lesson:)
        CourseLibraryActivity.hide_activity(hidden_activity.id, course.id)

        results = described_class.all_for_program(program, sections: course.sections)

        expect(results).to eq [hidden_activity.id]
      end

      it 'does not return activities from another program' do
        create(:activity, lesson: other_program.lessons.first)

        results = described_class.all_for_program(program, sections: course.sections)

        expect(results).to eq []
      end

      it 'does not return deleted activities' do
        create(:activity, lesson:, toc_location: nil)

        results = described_class.all_for_program(program, sections: course.sections)

        expect(results).to eq []
      end

      it 'returns visible instructor created activities for the given program' do
        instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.all_for_program(program, sections: course.sections)

        expect(results).to eq [instructor_activity.id]
      end


      it 'returns hidden instructor created activities for the given program' do
        instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: true)

        results = described_class.all_for_program(program, sections: course.sections)

        expect(results).to eq [instructor_activity.id]
      end

      it 'does not return instructor created activities from another program' do
        instructor_activity = create(
          :activity, lesson: other_program.lessons.first, instructor_revision_id: 1
        )
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.all_for_program(program, sections: course.sections)

        expect(results).to eq []
      end
    end

    context 'without a section,' do
      it 'returns visible activities for the given program' do
        visible_activity = create(:activity, lesson:)

        results = described_class.all_for_program(program)

        expect(results).to eq [visible_activity.id]
      end

      it 'returns hidden activities for the given program' do
        hidden_activity = create(:activity, lesson:)
        CourseLibraryActivity.hide_activity(hidden_activity.id, course.id)

        results = described_class.all_for_program(program)

        expect(results).to eq [hidden_activity.id]
      end

      it 'does not return activities from another program' do
        create(:activity, lesson: other_program.lessons.first)

        results = described_class.all_for_program(program)

        expect(results).to eq []
      end

      it 'does not return deleted activities' do
        create(:activity, lesson:, toc_location: nil)

        results = described_class.all_for_program(program)

        expect(results).to eq []
      end

      context 'when asking to include instructor created activities,' do
        it 'returns visible instructor created activities for the given program as visible' do
          instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

          results = described_class.all_for_program(program, include_instructor_content: true)

          expect(results).to eq [instructor_activity.id]
        end

        it 'returns hidden instructor created activities for the given program as visible' do
          instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: true)

          results = described_class.all_for_program(program, include_instructor_content: true)

          expect(results).to eq [instructor_activity.id]
        end

        it 'does not return instructor created activities from another program' do
          instructor_activity = create(
            :activity, lesson: other_program.lessons.first, instructor_revision_id: 1
          )
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

          results = described_class.all_for_program(program, include_instructor_content: true)

          expect(results).to eq []
        end
      end

      context 'when asking to exclude instructor created activities,' do
        it 'does not return visible instructor created activities for the given program' do
          instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

          results = described_class.all_for_program(program, include_instructor_content: false)

          expect(results).to eq []
        end

        it 'does not return hidden instructor created activities for the given program' do
          instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: true)

          results = described_class.all_for_program(program, include_instructor_content: false)

          expect(results).to eq []
        end

        it 'does not return instructor created activities from another program' do
          instructor_activity = create(
            :activity, lesson: other_program.lessons.first, instructor_revision_id: 1
          )
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

          results = described_class.all_for_program(program, include_instructor_content: false)

          expect(results).to eq []
        end
      end
    end
  end

  describe '.all_for_lesson' do
    let(:lesson) { program.lessons.first }
    let(:other_lesson) { program.lessons.last }

    context 'with a section' do
      include_examples 'with current_user param', 'all_for_lesson', 'lesson' do
        before do
          co_instructor_activities.each { |activity| activity.update!(lesson_id: lesson.id) }
          instructor_activity.update!(lesson_id: lesson.id)
        end
      end

      it 'returns visible activities for the given lesson as visible' do
        visible_activity = create(:activity, lesson:)

        results = described_class.all_for_lesson(lesson, sections: course.sections)

        expect(results).to eq [visible_activity.id]
      end

      it 'returns hidden activities for the given lesson as hidden' do
        hidden_activity = create(:activity, lesson:)
        CourseLibraryActivity.hide_activity(hidden_activity.id, course.id)

        results = described_class.all_for_lesson(lesson, sections: course.sections)

        expect(results).to eq [hidden_activity.id]
      end

      it 'does not return activities from another lesson' do
        create(:activity, lesson: other_lesson)

        results = described_class.all_for_lesson(lesson, sections: course.sections)

        expect(results).to eq []
      end

      it 'does not return deleted activities' do
        create(:activity, lesson:, toc_location: nil)

        results = described_class.all_for_lesson(lesson, sections: course.sections)

        expect(results).to eq []
      end

      it 'returns visible instructor created activities for the given lesson as visible' do
        instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.all_for_lesson(lesson, sections: course.sections)

        expect(results).to eq [instructor_activity.id]
      end

      it 'returns hidden instructor created activities for the given lesson as hidden' do
        instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: true)

        results = described_class.all_for_lesson(lesson, sections: course.sections)

        expect(results).to eq [instructor_activity.id]
      end

      it 'does not return instructor created activities from another lesson' do
        instructor_activity = create(
          :activity, lesson: other_lesson, instructor_revision_id: 1
        )
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.all_for_lesson(lesson, sections: course.sections)

        expect(results).to eq []
      end
    end

    context 'without a section,' do
      it 'returns visible activities for the given lesson as visible' do
        visible_activity = create(:activity, lesson:)

        results = described_class.all_for_lesson(lesson, sections: course.sections)

        expect(results).to eq [visible_activity.id]
      end

      it 'returns hidden activities for the given lesson as visible' do
        hidden_activity = create(:activity, lesson:)
        CourseLibraryActivity.hide_activity(hidden_activity.id, course.id)

        results = described_class.all_for_lesson(lesson)

        expect(results).to eq [hidden_activity.id]
      end

      it 'does not return activities from another lesson' do
        create(:activity, lesson: other_lesson)

        results = described_class.all_for_lesson(lesson)

        expect(results).to eq []
      end

      it 'does not return deleted activities' do
        create(:activity, lesson:, toc_location: nil)

        results = described_class.all_for_lesson(lesson)

        expect(results).to eq []
      end

      context 'when asking to include instructor created activities,' do
        it 'returns visible instructor created activities for the given lesson as visible' do
          instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

          results = described_class.all_for_lesson(lesson, include_instructor_content: true)

          expect(results).to eq [instructor_activity.id]
        end

        it 'returns hidden instructor created activities for the given lesson as visible' do
          instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: true)

          results = described_class.all_for_lesson(lesson, include_instructor_content: true)

          expect(results).to eq [instructor_activity.id]
        end

        it 'does not return instructor created activities from another lesson' do
          instructor_activity = create(
            :activity, lesson: other_lesson, instructor_revision_id: 1
          )
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

          results = described_class.all_for_lesson(lesson, include_instructor_content: true)

          expect(results).to eq []
        end
      end

      context 'when asking to exclude instructor created activities,' do
        it 'does not return visible instructor created activities for the given lesson' do
          instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

          results = described_class.all_for_lesson(lesson, include_instructor_content: false)

          expect(results).to eq []
        end

        it 'does not return hidden instructor created activities for the given lesson' do
          instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: true)

          results = described_class.all_for_lesson(lesson, include_instructor_content: false)

          expect(results).to eq []
        end

        it 'does not return instructor created activities from another lesson' do
          instructor_activity = create(
            :activity, lesson: other_lesson, instructor_revision_id: 1
          )
          CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

          results = described_class.all_for_lesson(lesson, include_instructor_content: false)

          expect(results).to eq []
        end
      end
    end
  end

  describe '.all_for_toc_location' do
    let(:toc_location) { 999 }
    let(:other_toc_location) { 998 }

    context 'with a section,' do
      include_examples 'with current_user param', 'all_for_toc_location', 'toc_location' do
        let(:lesson) { program.lessons.first }

        before do
          co_instructor_activities.each { |activity| activity.update!(toc_location:) }
          instructor_activity.update!(toc_location:)
        end
      end

      it 'returns visible activities for the given toc as visible' do
        visible_activity = create(:activity, toc_location:)

        results = described_class.all_for_toc_location(toc_location, sections: course.sections)

        expect(results).to eq [visible_activity.id]
      end

      it 'returns hidden activities for the given toc as hidden' do
        hidden_activity = create(:activity, toc_location:)
        CourseLibraryActivity.hide_activity(hidden_activity.id, course.id)

        results = described_class.all_for_toc_location(toc_location, sections: course.sections)

        expect(results).to eq [hidden_activity.id]
      end

      it 'does not return activities from another toc' do
        create(:activity, toc_location: other_toc_location)

        results = described_class.all_for_toc_location(toc_location, sections: course.sections)

        expect(results).to eq []
      end

      it 'does not return deleted activities' do
        create(:activity, toc_location: nil)

        results = described_class.all_for_toc_location(toc_location, sections: course.sections)

        expect(results).to eq []
      end

      it 'returns visible instructor created activities for the given toc as visible' do
        instructor_activity = create(:activity, toc_location:, instructor_revision_id: 1)
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.all_for_toc_location(toc_location, sections: course.sections)

        expect(results).to eq [instructor_activity.id]
      end

      it 'returns hidden instructor created activities for the given toc as hidden' do
        instructor_activity = create(:activity, toc_location:, instructor_revision_id: 1)
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: true)

        results = described_class.all_for_toc_location(toc_location, sections: course.sections)

        expect(results).to eq [instructor_activity.id]
      end

      it 'does not return instructor created activities from another toc' do
        instructor_activity = create(
          :activity, toc_location: other_toc_location, instructor_revision_id: 1
        )
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.all_for_toc_location(toc_location, sections: course.sections)

        expect(results).to eq []
      end
    end

    context 'without a section,' do
      it 'returns visible activities for the given toc as visible' do
        visible_activity = create(:activity, toc_location:)

        results = described_class.all_for_toc_location(toc_location)

        expect(results).to eq [visible_activity.id]
      end

      it 'returns hidden activities for the given toc as visible' do
        hidden_activity = create(:activity, toc_location:)
        CourseLibraryActivity.hide_activity(hidden_activity.id, course.id)

        results = described_class.all_for_toc_location(toc_location)

        expect(results).to eq [hidden_activity.id]
      end

      it 'does not return activities from another toc' do
        create(:activity, toc_location: other_toc_location)

        results = described_class.all_for_toc_location(toc_location)

        expect(results).to eq []
      end

      it 'does not return deleted activities' do
        create(:activity, toc_location: nil)

        results = described_class.all_for_toc_location(toc_location)

        expect(results).to eq []
      end
    end

    context 'when toc location is nil' do
      it 'does not return any activities' do
        create(:activity, toc_location: nil)

        results = described_class.all_for_toc_location(nil)

        expect(results).to eq []
      end
    end

    context 'when toc location is composed of nil elements' do
      it 'does not return any activities' do
        create(:activity, toc_location: nil)

        results = described_class.all_for_toc_location([nil])

        expect(results).to eq []
      end
    end
  end

  describe '.all_unassigned_by_program' do
    let(:other_program) { create(:program_with_toc_entries) }
    let(:lesson) { program.lessons.first }
    let(:other_lesson) { other_program.lessons.first }
    let(:section) { create(:section, course:) }

    context 'with a course,' do
      it 'returns visible activities for the given program as visible' do
        visible_activity = create(:activity, lesson:)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [section],
          current_user: section.instructor
        )

        expect(results).to eq [visible_activity.id]
      end

      it 'returns hidden activities for the given program as hidden' do
        hidden_activity = create(:activity, lesson:)
        CourseLibraryActivity.hide_activity(hidden_activity.id, course.id)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [section],
          current_user: section.instructor
        )

        expect(results).to eq [hidden_activity.id]
      end

      it 'does not return activities from another program' do
        create(:activity, lesson: other_program.lessons.first)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [section],
          current_user: section.instructor
        )

        expect(results).to eq []
      end

      it 'does not return deleted activities' do
        create(:activity, lesson:, toc_location: nil)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [section],
          current_user: section.instructor
        )

        expect(results).to eq []
      end

      it 'does not return instructor created activities for the given program' do
        instructor_activity = create(:activity, lesson:, instructor_revision_id: 1)
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [section],
          current_user: section.instructor
        )

        expect(results).to eq []
      end

      it 'does not return assigned activities for the given program' do
        activity = create(:activity, lesson:)
        create(:assignment, assignable: activity, section:)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [section],
          current_user: section.instructor
        )

        expect(results).to eq []
      end

      it 'does not return instructor created activities from another program' do
        instructor_activity = create(
          :activity, lesson: other_program.lessons.first, instructor_revision_id: 1
        )
        CourseLibraryActivity.create!(activity: instructor_activity, course:, hidden: false)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [section],
          current_user: section.instructor
        )

        expect(results).to eq []
      end
    end

    context 'without a course,' do
      it 'returns visible activities for the given program as visible' do
        visible_activity = create(:activity, lesson:)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [],
          current_user: section.instructor
        )

        expect(results).to eq [visible_activity.id]
      end

      it 'returns hidden activities for the given program as visible' do
        hidden_activity = create(:activity, lesson:)
        CourseLibraryActivity.hide_activity(hidden_activity.id, course.id)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [],
          current_user: section.instructor
        )

        expect(results).to eq [hidden_activity.id]
      end

      it 'does not return activities from another program' do
        create(:activity, lesson: other_program.lessons.first)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [],
          current_user: section.instructor
        )

        expect(results).to eq []
      end

      it 'does not return deleted activities' do
        create(:activity, lesson:, toc_location: nil)

        results = described_class.all_unassigned_by_program(
          program.id,
          sections: [],
          current_user: section.instructor
        )

        expect(results).to eq []
      end
    end
  end
end
