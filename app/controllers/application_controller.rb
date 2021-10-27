class ApplicationController < ActionController::API
  def event
    payload.event
  end

  def payload
    @payload ||= Slack::Messages::Message.new(request.env['slack.payload'])
  end

  def client
    @_client ||= Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

end
