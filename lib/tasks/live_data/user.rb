require 'tasks/print_decorator'

module LiveData
  class User
    include  ::PrintDecorator

    def reset_all_passwords
      print_message("Resetting M3 users passwords", '', 6)

      ::User.all.each do |user|
        user.password = 'password'
        user.password_confirmation = 'password'
        user.save!
      end
      print_message("password resetted to 'password' for M3", 'H3', 2, 'green')
    end
  end
end
