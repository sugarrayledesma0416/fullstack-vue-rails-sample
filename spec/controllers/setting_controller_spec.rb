describe SettingController do
  describe 'POST sort_courses' do
    let(:user) { create(:instructor) }

    before do
      fake_login(user)
    end

    it 'saves course order as a user setting record' do
      post :sort_courses, params: { course_order: '1,2,3', program_id: '79', format: :json }
      expect(user.setting(:course_order_79)).to eq('1,2,3')
    end

    it 'updates course order when the setting record already exists' do
      Setting.create!(user_id: user.id, name: 'course_order_79', value: '1,2,3')
      post :sort_courses, params: { course_order: '4,5,6', program_id: '79', format: :json }

      expect(user.setting(:course_order_79)).to eq('4,5,6')
    end
  end
end
