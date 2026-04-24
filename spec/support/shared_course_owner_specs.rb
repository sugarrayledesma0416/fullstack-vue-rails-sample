shared_examples_for 'a previous owner that is not a valid instructor' do
  it 'does not transfer the course' do
    updater.update

    expect(course.reload.owner).to eq(previous_owner)
  end

  it 'sets an error message' do
    updater.update

    expect(updater.errors).to contain_exactly(
      "#{previous_owner.full_name} is not a " \
      "#{CourseOwnerUtilities::ALLOWED_TYPES_FOR_TRANSFER} instructor."
    )
  end
end

shared_examples_for 'a new owner that is not a valid instructor' do
  it 'does not transfer the course' do
    updater.update

    expect(course.reload.owner).to eq(previous_owner)
  end

  it 'sets an error message' do
    updater.update

    expect(updater.errors).to contain_exactly(
      "#{new_owner.full_name} is not a " \
      "#{CourseOwnerUtilities::ALLOWED_TYPES_FOR_TRANSFER} instructor."
    )
  end
end

shared_examples_for 'a new owner that is not in one of the schools ' \
                    'the current owner belongs to' do
  it 'does not transfer the course' do
    updater.update

    expect(course.reload.owner).to eq(previous_owner)
  end

  it 'sets an error message' do
    updater.update

    expect(updater.errors).to contain_exactly(
      "#{new_owner.full_name} is not an instructor " \
      'in a school the current owner belongs to.'
    )
  end
end

shared_examples_for 'a new owner that is a valid instructor in one of the schools ' \
                    'the current owner belongs to' do
  it 'transfers all the sections' do
    updater.update

    sections.each do |section|
      expect(section.reload.instructor).to eq(new_owner)
    end
  end

  it 'transfers the forums' do
    forum = create(:forum, section: sections.first, instructor: previous_owner)

    updater.update

    expect(forum.reload.instructor).to eq(new_owner)
  end

  it 'transfers the course' do
    updater.update

    expect(course.reload.owner).to eq(new_owner)
  end

  it 'makes the new owner an instructor in each section' do
    updater.update

    [section_1, section_2].each do |section|
      expect(
        SectionInstructor.where(
          section: section,
          instructor: new_owner,
          role: 'Instructor'
        )
      ).to exist
    end
  end

  it 'does not change the role of the other co-instructors' do
    expect do
      updater.update
    end.not_to change { section_1_different_instructor.reload.role }
  end

  it 'deletes the section_instructor record for the previous owner in ' \
    'each section' do
    updater.update

    [
      section_1_previous_owner,
      section_2_previous_owner
    ].each do |section_instructor|
      expect { section_instructor.reload }.to raise_error(
        ActiveRecord::RecordNotFound
      )
    end
  end

  it 'does not set any error message' do
    updater.update

    expect(updater.errors).to be_empty
  end
end

shared_examples_for 'a new owner that is co-instructor in a section of the course' do
  it 'makes the new owner an instructor in each section' do
    section_1_new_owner = create(
      :section_instructor,
      section: section_1,
      instructor: new_owner
    )
    section_2_new_owner = create(
      :section_co_instructor,
      section: section_2,
      instructor: new_owner
    )

    updater.update

    expect(section_1_new_owner.reload.role).to eq('Instructor')
    expect(section_2_new_owner.reload.role).to eq('Instructor')
  end
end

shared_examples_for 'a previous and new owner that have different instructor types.' do
  it 'does not transfer the course' do
    updater.update

    expect(course.reload.owner).to eq(previous_owner)
  end

  it 'sets an error message' do
    updater.update

    expect(updater.errors).to contain_exactly(
      "#{new_owner.full_name} is not a #{previous_owner.instructor_type} instructor."
    )
  end
end

shared_examples_for 'a course that is closed' do
  it 'does not transfer the course' do
    updater.update

    expect(course.owner.reload).to eq(previous_owner)
  end

  it 'sets an error message' do
    updater.update

    expect(updater.errors).to contain_exactly(
      'The course is closed.'
    )
  end
end

shared_examples_for 'a course that is closed but editable' do
  it 'transfers the course' do
    expect(course).to be_editable
    expect(course).to be_closed

    updater.update

    expect(course.owner.reload).to eq(new_owner)
  end
end

shared_examples_for 'a course that is archived' do
  it 'does not transfer the course' do
    updater.update

    expect(course.owner.reload).to eq(previous_owner)
  end

  it 'sets an error message' do
    updater.update

    expect(updater.errors).to contain_exactly(
      'The course is archived.'
    )
  end
end

shared_examples_for 'a new owner with invalid instructor type' do
  let(:new_owner) { create(:instructor) }

  it 'shows an error message and renders the show view' do
    do_request

    expect(response).to render_template(:show)
    expect(flash[:error]).to eq(
      'Failed to update the course.'
    )

    expect(assigns(:course_name)).to eq(course.name)
    expect(assigns(:errors)).to contain_exactly(

      "#{new_owner.full_name} is not a #{CourseOwnerUtilities::ALLOWED_TYPES_FOR_TRANSFER} instructor."
    )

    expect(assigns(:presenter)).to be_a(Support::CourseOwnerPresenter)
    expect(assigns(:presenter).instructor).to eq(instructor)
  end
end
