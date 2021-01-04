require 'test_helper'

class ReactionsControllerTest < ActionDispatch::IntegrationTest
  test "#added" do
    VCR.use_cassette 'slack/reaction_add' do
      post events_url, params: {
        type: "reaction_added",
        event: {
          reaction: 'example',
          item: {
            channel: 'EXAMPLE',
            ts: '1598587862.219000'
          }
        }
      }.to_json
    end
  end
end
