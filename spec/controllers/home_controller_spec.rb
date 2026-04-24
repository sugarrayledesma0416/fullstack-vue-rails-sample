describe HomeController do
  describe '#ua_home' do
    it 'redirects to ua' do
      get :ua_home
      if defined? UA_URL
        expect(response).to redirect_to("#{UA_URL}/home")
      else
        expect(response).to redirect_to('https://www.vhlcentral.com/home')
      end
    end

    it 'does not do any filters' do
      expect(controller).not_to receive(:set_time_zone)
      get :ua_home
    end
  end
end
