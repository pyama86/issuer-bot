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

  def slack
    @_client ||= Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def create_issue!(repo, labels)
    Rails.logger.info event.inspect
    message = SlackReaction.find_reacted_message(event)
    Rails.logger.info message.inspect
    title  = "%s からの対応依頼(%s)" % [user_name, channel_name]
    octkit.create_issue(repo, title, body(message), labels: labels)
  end

  def user_name
    slack.users_info(user: event.item_user || event.user).user.name
  end

  def channel_name
    slack.conversations_info(channel: event.item.channel).channel.name
  end

  def members
    Rails.cache.fetch("slack_members", expires_in: 60.minutes) do
      members = []
      next_cursor = nil
      loop do
        slack_users = slack.users_list({limit: 1000, cursor: next_cursor})
        members << slack_users['members']
        next_cursor = slack_users['response_metadata']['next_cursor']
        break if next_cursor.empty?
      end
      members.flatten
    end
  end

  def groups
    Rails.cache.fetch("slack_groups", expires_in: 60.minutes) do
      groups = []
      next_cursor = nil
      loop do
        slack_groups = slack.groups_list({limit: 1000, cursor: next_cursor})
        groups << slack_groups['groups']
        next_cursor = slack_groups['response_metadata']['next_cursor']
        break if next_cursor.empty?
      end
      groups.flatten
    end
  end

  def body(message)
    Rails.logger.info message.inspect
    txt = if message["attachments"].nil? ||
              message["attachments"].size.zero? ||
              (!message["attachments"].first["service_name"].nil? && message["attachments"].first["service_name"].empty?)
        message["text"]
      else
        message["attachments"].first["text"].nil? || message["attachments"].first["text"].empty? ? message["attachments"].first["title"] : message["attachments"].first["text"]
      end

    txt.gsub!(/<!subteam\^[A-Z0-9]{9}\|(@.*?)>/, "\\1")
    ids = txt.scan(/<@[A-Z0-9]{9}>/)
    ids.each do |id|
      id.gsub!(/<@|>/, "")
      target = members.find{|m| m["id"] == id } || groups.find{|m| m["id"] == id}
      txt.gsub!(/<@#{id}>/, "@#{target["name"]}") if target
    end

    <<EOS
## メッセージ
#{txt}
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
