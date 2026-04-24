class UploadInstuctorProgramPersonalization < ActiveRecord::Migration[4.2]
  class User < ActiveRecord::Base
    default_scope { where(users: { is_archived: false }) }
  end

  def self.up
    User.where(account_type: 'Instructor').find_in_batches do |user_group|
       user_group.each do |user|
         user.programs_with_access.each do |program|
           PersonalizedProgram.create!(
             { user_id: user.id, program_id: program.id }
           ) unless PersonalizedProgram.where(
             user_id: user.id, program_id: program.id
           ).exists?
         end
       end
    end
  end

  def self.down
    User.where(account_type: 'Instructor').find_in_batches do |user_group|
       user_group.each do |user|
         user.programs.each do |program|
           personalized_program = PersonalizedProgram.where(
             user_id: user.id, program_id: program.id
           ).first
           personalized_program.destroy if personalized_program
         end
       end
    end
  end
end
