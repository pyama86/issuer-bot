class CreateIssuerJob < ApplicationJob
  queue_as :default
  def client
    @_client ||= Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def perform(channel, event)
    event = RecursiveOpenStruct.new(event)
    service = GithubIssueService.new(event: event)
    issue   = service.create_issue!(channel.org_repo, channel.labels)
    text    = "%s にissueを作成しました。" % issue.html_url
    client.chat_postMessage(text: text, channel: event.item.channel)
  end
end
