module CASClient	
  class LogWrapper	

    # The rubycas-client gem does some logging that we'd like to suppress in the live env to reduce	
    # what we send to papertrail. 	
    # Since live is set to log at the info level, we're monkey patching the Cas logger so that	
    # all info and warn-level messages get sent as debug-level messages instead.	

    def info(*args)	
      self.send(:debug, *args)	
    end	

    def warn(*args)	
      self.send(:debug, *args)	
    end	

   end	
end
