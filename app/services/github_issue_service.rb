# frozen_string_literal: true

class GithubIssueService
  include ActiveModel::Model
  attr_accessor :event

  def web_endpoint
    ENV['GITHUB_WEB'] || 'https://github.com'
  end

  def self.slack
    @_client ||= Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def issue_url(repo, labels, message = nil)
    Rails.logger.info event.inspect
    message ||= SlackReaction.find_reacted_message(event)
    Rails.logger.info message.inspect
    param = {
      body: body(message),
      labels: labels
    }

    format("#{web_endpoint}/%s/issues/new?%s", repo, param.to_query)
  end

  def self.members
    Rails.cache.fetch('slack_members', expires_in: 60.minutes) do
      members = []
      next_cursor = nil
      loop do
        slack_users = slack.users_list(limit: 1000, cursor: next_cursor)
        members << slack_users['members']
        next_cursor = slack_users['response_metadata']['next_cursor']
        break if next_cursor.empty?
      end
      members.flatten
    end
  end

  def self.groups
    Rails.cache.fetch('slack_groups', expires_in: 60.minutes) do
      groups = []
      next_cursor = nil
      loop do
        slack_groups = slack.groups_list(limit: 1000, cursor: next_cursor)
        groups << slack_groups['groups']
        next_cursor = slack_groups['response_metadata']['next_cursor']
        break if next_cursor.empty?
      end
      groups.flatten
    end
  end

  def self.parse_message(message)
    Rails.logger.info message.inspect
    txt = if message['attachments'].nil? ||
             message['attachments'].size.zero? ||
             (!message['attachments'].first['service_name'].nil? && message['attachments'].first['service_name'].empty?)
            message['text']
          else
            message['attachments'].first['text'].nil? || message['attachments'].first['text'].empty? ? message['attachments'].first['title'] : message['attachments'].first['text']
      end

    txt.gsub!(/<!subteam\^[A-Z0-9]{9}\|(@.*?)>/, '\\1')
    ids = txt.scan(/<@[A-Z0-9]{9}>/)
    ids.each do |id|
      id.gsub!(/<@|>/, '')
      target = members.find { |m| m['id'] == id } || groups.find { |m| m['id'] == id }
      txt.gsub!(/<@#{id}>/, "@#{target['name']}") if target
    end
    txt
  end

  def body(message)
    <<~EOS
      ## メッセージ
      #{GithubIssueService.parse_message(message)}
      ## 参考情報
      - [Slackリンク](#{slack_link})
    EOS
  end

  def slack_link
    timestamp = event.item.ts.delete('.')
    path      = "archives/#{event.item.channel}/p#{timestamp}"
    File.join(ENV['SLACK_WORKSPACE_URL'] || 'https://slack.com', path)
  end
end
