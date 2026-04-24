describe ChatClickLogsController do
  def mock_chat_click_log(stubs={})
    @mock_chat_click_log ||= double(ChatClickLog, stubs)
  end

  describe 'PUT log' do
    describe 'with valid params' do
      it 'assigns a newly logd chat_click_log as @chat_click_log' do
        chat_log = mock_chat_click_log(save: true)
        expect(chat_log).to receive(:save)
        allow(ChatClickLog).to receive(:new).with(hash_including('url' => '/some/url')).and_return(chat_log)
        put :log, params: { chat_click_log: { url: '/some/url' } }, xhr: true
        expect(assigns(:chat_click_log)).to eq(mock_chat_click_log)
      end
    end

    describe 'with invalid params' do
      it 'assigns a newly logd but unsaved chat_click_log as @chat_click_log' do
        chat_log = mock_chat_click_log(save: false)
        expect(chat_log).to receive(:save)
        allow(ChatClickLog).to receive(:new).with(hash_including('url' => '/some/url')).and_return(chat_log)
        put :log, params: { chat_click_log: { url: '/some/url' } }, xhr: true
        expect(assigns(:chat_click_log)).to eq(mock_chat_click_log)
      end
    end
  end
end
