# encoding: utf-8

initial_queue_size = ScheduledJob.queued.size

TestWorker.perform_async(1, 'Test')
puts "new queued jobs: #{ScheduledJob.queued.size - initial_queue_size}\n"
sleep 2
puts "remaining queued jobs: #{ScheduledJob.queued.size - initial_queue_size}\n"
puts "running jobs: #{ScheduledJob.running.size}\n"
