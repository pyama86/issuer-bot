module Rack
  module Slack
    class Event
      def initialize(app, endpoint:)
        @app = app
        @endpoint = endpoint
      end

      def call(env)
        if env['PATH_INFO'] == @endpoint
          annotate(env)
        end

       @app.call(env)
      end

      private

      def annotate(env)
        request = Rack::Request.new(env)
        payload = JSON.parse(request.body.read)
        if payload['type'] == 'event_callback'
          env['slack.event.type'] = payload['event']['type'].to_sym
        else
          env['slack.event.type'] = payload['type'].to_sym
        end

        env['slack.payload'] = payload

        request.body.rewind
      end
    end
  end
end
