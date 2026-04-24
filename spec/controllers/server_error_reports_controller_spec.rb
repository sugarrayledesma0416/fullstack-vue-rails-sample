describe ServerErrorReportsController do
  describe '#update' do
    it 'updates the server error logstash report with the specified id' do
      server_error = (double(ServerErrorReportDispatcher, id: 'server_error_uuid'))
      server_error_params = { id: server_error.id, user_comment: 'user_comment' }

      expect(ServerErrorReportDispatcher).to receive(:new)
        .with(hash_including(server_error_params))
        .and_return(server_error)
      expect(server_error).to receive(:dispatch)
      allow(controller).to receive(:render)

      put :update, params: { id: server_error.id, user_comment: 'user_comment' }
    end
  end
end
