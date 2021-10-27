module Rack
  module Slack
    class Auth
      attr_accessor :slack_secret, :version

      def initialize(app, slack_secret, path: nil, version: "v0")
        @app = app
        @slack_secret = slack_secret
        @version = version
        @path = path
      end

      def call(env)

        request = Rack::Request.new(env)
        if !path_match?(request) || request.env['slack.event.type'] == :url_verification
          return @app.call(env)
        end

        timestamp = request.env["HTTP_X_SLACK_REQUEST_TIMESTAMP"]

        # check that the timestamp is recent (~5 mins) to prevent replay attacks
        if Time.at(timestamp.to_i) < Time.now - (60 * 5)
          return unauthorized
        end

        # generate hash
        request_body = request.body.read

        computed_signature = generate_hash(timestamp, request_body)

        # compare generated hash with slack signature
        slack_signature = request.env["HTTP_X_SLACK_SIGNATURE"]

        if computed_signature == slack_signature
          request.body.rewind
          return @app.call(env)
        end

        unauthorized
      end

      def generate_hash(timestamp, request_body)
        sig_basestring = "#{self.version}:#{timestamp}:#{request_body}"
        digest = OpenSSL::Digest::SHA256.new
        hex_hash = OpenSSL::HMAC.hexdigest(digest, self.slack_secret, sig_basestring)

        "#{self.version}=#{hex_hash}"
      end

      private

      def path_match?(request)
        if @path
          request.env["PATH_INFO"] == @path
        else
          true
        end
      end

      def unauthorized
        return [ 401,
          { CONTENT_TYPE => 'text/plain',
            CONTENT_LENGTH => '0' },
          []
        ]
      end

    end
  end
end
