class SlackReaction
  class << self
    def client
      Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
    end

    def find_reacted_message(event)
      result = client.conversations_history(
        channel: event.item.channel,
        oldest: event.item.ts,
        latest: event.item.ts,
        inclusive: true,
        limit: 1,
      )

      result = client.conversations_replies(
        channel: event.item.channel,
        ts: event.item.ts,
        oldest: event.item.ts,
        latest: event.item.ts,
        inclusive: true,
        limit: 1,
      ) if result.messages.size.zero?

      result.messages.first
    end
  end
end
