module Sidekiq
  module Middleware
    module Server
      class Logstash
        def initialize(opts)
          @logstash = opts[:client]
        end

        def call(worker, item, _queue)
          start_time = Time.now

          yield

          send_logstash_data(worker, item, start_time)
        rescue StandardError => e
          # capture any fatal job errors so we can
          # add error information to logstash payload.
          error_data = {
            error_class: e.class.name,
            error_message: e.message,
            error_location: e.backtrace[0]
          }
          send_logstash_data(worker, item, start_time, error_data)
          # then re-raise the error so Sidekiq will know the job failed,
          # record the failure and queue a re-try if the worker
          # has re-tries enabled.
          raise e
        end

        def send_logstash_data(worker, item, start_time, error_data = {})
          if error_data.empty?
            @logstash.info(build_data_hash(worker, item, start_time))
          else
            @logstash.error(build_data_hash(worker, item, start_time, error_data))
          end
        end

        private def build_data_hash(worker, item, start_time, error_data = {})
          worker_data(worker).merge(
            application: application_name,
            concurrent_job_count: concurrent_job_count,
            duration: job_duration(start_time),
            environment: ::Rails.env,
            retry_count: (item['retry_count'].nil? ? 0 : item['retry_count'].to_i + 1),
            start_time: start_time,
            vhl_component: 'sidekiq',
            worker_class: worker.class.name
          ).merge(error_data)
        end

        private def application_name
          if ::Rails::VERSION::MAJOR >= 6
            ::Rails.application.class.module_parent_name
          else
            ::Rails.application.class.parent_name
          end
        end

        private def worker_data(worker)
          # the worker keys should not conflict but if they do
          # we want the module keys to overwrite them
          if worker.respond_to?(:logger_data)
            worker.logger_data
          else
            {}
          end
        end

        def job_duration(start_time)
          ms_time_diff(Time.now, start_time)
        end
        private :job_duration

        def concurrent_job_count
          # since this is run after the job finishes,
          # # we'll add 1 for self
          ::Sidekiq::Workers.new.size + 1
        end

        def ms_time_diff(end_time, start_time)
          # the result of the subtraction returns seconds as a floating
          # point number with 14 decimal places. We want to return the
          # number of milliseconds as an integer.
          ((end_time - start_time) * 1000).round
        end
        private :ms_time_diff
      end
    end
  end
end
