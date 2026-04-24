class AddSectionIdAndRequestTypeIndexToHelpRequests < ActiveRecord::Migration[4.2]
  def self.up
    add_index :help_requests, [:section_id, :request_type], :length => {:request_type => 20}
  end

  def self.down
    remove_index :help_requests, :column => [:section_id, :request_type]
  end
end
