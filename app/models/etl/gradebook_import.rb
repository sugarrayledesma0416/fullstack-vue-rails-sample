module Etl
  module GradebookImport
    def run(num_messages)
      Kiba.run(Etl::GradebookImport::MessageEtl.setup(num_messages))
    rescue StandardError => e
      VHLMonitor.notify(e)
      raise e
    end
    module_function :run
  end
end
