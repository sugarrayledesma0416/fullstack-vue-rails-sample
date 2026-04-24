describe Enterprise::BreadcrumbHelper do
  describe '#build_breadcrumb' do
    let!(:institution_admin) { create(:institution_admin) }
    let!(:school) { create(:school) }
    let!(:program) { create(:program, title: 'Sample program') }
    let!(:course) { create(:enterprise_course, name: 'Sample course')}
    let!(:presenter) { InstitutionAdminDashboardPresenter.new(institution_admin, school.id, program.id, '2020', course.id) }

    context 'when action is courses' do
      it 'returns the bradcrumb for the course page' do
        result = helper.build_breadcrumb(presenter, 'courses')

        expect(result).to include('Dashboard')
        expect(result).to include('Sample program')
        expect(result).not_to include('Sample course')
      end
    end

    context 'when action is sections' do
      it 'returns the bradcrumb for the sections page' do
        result = helper.build_breadcrumb(presenter, 'sections')

        expect(result).to include('Dashboard')
        expect(result).to include('Sample program')
        expect(result).to include('Sample course')
      end
    end
  end
end
