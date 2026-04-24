describe SectionDataDeleter do
  let(:section) { create(:section) }
  let(:other_section) { create(:section) }
  let(:deleter) { described_class.new(section.id) }

  describe '#delete_section_data' do
    it 'deletes announcement recordss associated with the section' do
      announcement = create(:announcement)
      other_announcement = create(:announcement)
      # No factory for AnnouncementSection
      AnnouncementSection.create(section_id: section.id,
                                 announcement_id: announcement.id)
      AnnouncementSection.create(section_id: other_section.id,
                                 announcement_id: other_announcement.id)
      deleter.delete_section_data
      expect(Announcement.where(id: announcement.id)).to be_empty
      expect(Announcement.where(id: other_announcement.id)).to_not be_nil
      expect(AnnouncementSection.where(section_id: section.id)).to be_empty
      expect(AnnouncementSection.where(section_id: other_section.id)).to_not be_nil
    end

    it 'deletes assessment student time limits associated with the section' do
      create(:assessment_student_time_limit, section_id: section.id)
      create(:assessment_student_time_limit, section_id: other_section.id)
      deleter.delete_section_data
      expect(AssessmentStudentTimeLimit.where(section_id: section.id)).to be_empty
      expect(AssessmentStudentTimeLimit.where(section_id: other_section.id)).to_not be_empty
    end

    it 'deletes assignments associated with the section' do
      create(:assignment, section: section)
      create(:assignment, section: other_section)
      deleter.delete_section_data
      expect(Assignment.where(section_id: section.id)).to be_empty
      expect(Assignment.where(section_id: other_section.id)).not_to be_empty
    end

    it 'deletes attempts associated with the section' do
      create(:attempt, section: section)
      create(:attempt, section: other_section)
      deleter.delete_section_data
      expect(Attempt.where(section_id: section.id)).to be_empty
      expect(Attempt.where(section_id: other_section.id)).to_not be_empty
    end

    it 'deletes enrollments associated with the section' do
      create(:enrollment, section: section)
      create(:enrollment, section: other_section)
      deleter.delete_section_data
      expect(Enrollment.where(section_id: section.id)).to be_empty
      expect(Enrollment.where(section_id: other_section.id)).not_to be_empty
    end

    it 'deletes feedback items associated with the section' do
      create(:feedback_item, section: section)
      create(:feedback_item, section: other_section)
      deleter.delete_section_data
      expect(FeedbackItem.where(section_id: section.id)).to be_empty
      expect(FeedbackItem.where(section_id: other_section.id)).to_not be_empty
    end

    it 'deletes forums associated with the section' do
      create(:forum, section: section)
      create(:forum, section: other_section)
      deleter.delete_section_data
      expect(Forum.where(section_id: section.id)).to be_empty
      expect(Forum.where(section_id: other_section.id)).not_to be_empty
    end

    it 'deletes help requests associated with the section' do
      create(:help_request, section: section)
      create(:help_request, section: other_section)
      deleter.delete_section_data
      expect(HelpRequest.where(section_id: section.id)).to be_empty
      expect(HelpRequest.where(section_id: other_section.id)).not_to be_empty
    end

    it 'deletes notifications associated with the section' do
      create(:notification, section: section)
      create(:notification, section: other_section)
      deleter.delete_section_data
      expect(Notification.where(section_id: section.id)).to be_empty
      expect(Notification.where(section_id: other_section.id)).not_to be_empty
    end

    it 'deletes section-instructor records associated with the section' do
      create(:section_instructor, section: section)
      create(:section_instructor, section: other_section)
      deleter.delete_section_data
      expect(SectionInstructor.where(section_id: section.id)).to be_empty
      expect(SectionInstructor.where(section_id: other_section.id)).not_to be_empty
    end

    it 'deletes student spotcheck counts associated with the section' do
      create(:student_spotcheck_count, section: section)
      create(:student_spotcheck_count, section: other_section)
      deleter.delete_section_data
      expect(StudentSpotcheckCount.where(section_id: section.id)).to be_empty
      expect(StudentSpotcheckCount.where(section_id: other_section.id)).not_to be_empty
    end

    it 'deletes worksets associated with the section' do
      create(:workset, section: section)
      create(:workset, section: other_section)
      deleter.delete_section_data
      expect(Workset.where(section_id: section.id)).to be_empty
      expect(Workset.where(section_id: other_section.id)).not_to be_empty
    end

    it 'deletes the section' do
      deleter.delete_section_data
      expect(Section.find_by(id: section.id)).to be_nil
      expect(Section.find_by(id: other_section.id)).to_not be_nil
    end
  end
end
