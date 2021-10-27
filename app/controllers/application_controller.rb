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

  def octokit
    @_octokit ||= Octokit::Client.new(
      api_endpoint: ENV['GITHUB_API'] || 'api.github.com',
      access_token: ENV['GITHUB_TOKEN'],
      auto_paginate: true,
      per_page: 300
    )
  end
end
