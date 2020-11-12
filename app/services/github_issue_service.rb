class GithubIssueService
  include ActiveModel::Model
  attr_accessor :event

  def octkit
    @_o ||= Octokit::Client.new(
      access_token: ENV['GITHUB_TOKEN'],
      auto_paginate: true,
      api_endpoint: ENV['GITHUB_API'] || "https://api.github.com",
      web_endpoint: ENV['GITHUB_WEB'] || "https://github.com"
    )
  end

  def create_issue!(repo, labels)
    message = SlackReaction.find_reacted_message(event)
    parsed  = SlackReaction.parse_reaction_message(message)

    title  = "対応依頼(%s)" %  channel_name

    octkit.create_issue(repo, title, body(message), labels: labels)

  end

  def channel_name
    client = Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
    client.channels_info(channel: event.item.channel).channel.name
  end

  def body(message)
    <<EOS
## メッセージ
#{message[:text]}
## 参考情報
- [Slackリンク](#{slack_link})
EOS
  end

  def slack_link
    timestamp = event.item.ts.gsub(/\./, '')
    path      = "archives/#{event.item.channel}/p#{timestamp}"
    File.join(ENV['SLACK_WORKSPACE_URL'] || "https://slack.com", path)
  end
end
