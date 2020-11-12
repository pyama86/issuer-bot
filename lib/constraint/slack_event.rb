module Constraint
  class SlackEvent
    # @param [Symbol] type
    def initialize(event_type)
      @type = event_type
    end

    # @return [Bool]
    def matches?(request)
      request.env['slack.event.type'] == @type
    end
  end
end
