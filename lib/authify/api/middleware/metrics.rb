module Authify
  module API
    module Middleware
      # A middleware for analytics of rack requests
      class Metrics
        def initialize(app)
          @app     = app
          @metrics = Authify::API::Metrics.instance
          @key     = 'rack.action.response'
        end

        def call(env)
          path = env['PATH_INFO']
          routing_args = env['rack.routing_args'] || {}
          path = path.dup.tap do |old_path|
            routing_args.except(:format, :namespace, :catch).each do |param, arg|
              old_path.sub!(arg.to_s, ":#{param}")
            end
          end

          metric_name = "#{@key}.time.#{env['REQUEST_METHOD'].downcase}.#{path}"

          status, header, body = @metrics.time(metric_name) do
            @app.call env
          end

          @metrics.increment "#{@key}.count.#{env['REQUEST_METHOD'].downcase}.#{path}"

          [status, header, body]
        end
      end
    end
  end
end
