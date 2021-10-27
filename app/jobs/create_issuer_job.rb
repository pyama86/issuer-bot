class CreateIssuerJob < ApplicationJob
  queue_as :default
  def client
    @_client ||= Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def perform(channel, event)
    event = RecursiveOpenStruct.new(event)
    service = GithubIssueService.new(event: event)
    issue   = service.issue_url(channel.org_repo, channel.labels)
    text    = "<%s|こちらのリンク> をクリックしてIssueを作成してください。" % issue
    client.chat_postMessage(text: text, channel: event.item.channel)
  end
end
