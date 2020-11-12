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
      result.messages.first
    end

    def parse_reaction_message(message)
      if message["attachments"].nil? || message["attachments"].size.zero?
        {
          agent: nil,
          text: message.text,
        }
      else
        {
          text: message["attachments"].first["text"],
        }
      end
    end
  end
end
