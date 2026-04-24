LOCAL_ORIGINS = [/localhost(:\d+)?/,
                 /127\.0\.0\.1(:\d+)?/,
                 /192\.168\.\d{1,3}\.\d{1,3}(:\d+)?/,
                 /.*vhlcentral\.com/]

Rails.configuration.middleware.insert_after(ActionDispatch::DebugExceptions, Rack::Cors) do
  allow do
    origins LOCAL_ORIGINS
    resource %r{\/audio_samples.*}, headers: :any, methods: [:get, :post, :options]
    resource(
      %r{\/xapi/*},
      headers: :any,
      methods: %i[head get post put delete],
      credentials: true
    )
    resource(
      %r{/process_preview},
      headers: :any,
      methods: %i[post options],
      credentials: true
    )
  end
end

