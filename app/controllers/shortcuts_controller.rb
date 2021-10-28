class ShortcutsController < ApplicationController
  def create
    return render json: { "response_action": "clear" } if payload['type'] == 'block_actions' && payload['actions'].first['action_id'] == 'submit'
    blocks = Slack::BlockKit.blocks do |b|
      b.section do |s|
        s.plain_text(text: 'Chose Repository')
        s.static_select(placeholder: 'repo/org', action_id: "choice_repo", emoji: true) do |st|
          org_hash = Rails.cache.fetch("org_repos", expires_in: 60.minutes) do
            GithubRepos.often_use_repos
          end

          org_hash.each do |org,repos|
            st.option_group(label: org) do |og|
              repos.each_with_index do |r,index|
                i = payload['actions'].first['selected_option']['value'] == r rescue false
                og.option(value: r, text: r, emoji: true, initial: i) if index < 100
              end
            end
          end
        end
      end

      case payload['type']
      when 'message_action'
        b.divider
        b.header(text: "Metadata")
        b.section do |s|
          s.mrkdwn(text: "ts:#{payload['message']['ts']}")
        end
        b.section do |s|
          s.mrkdwn(text: "channel:#{payload['channel']['id']}")
        end
        Rails.cache.write(payload['message']['ts'], GithubIssueService.parse_message(payload['message']), expires_in: 10.minutes)
      when 'block_actions'
        case payload['actions'].first['action_id']
        when'choice_repo'
          event = RecursiveOpenStruct.new({
            item: {
              channel: get_metadata('channel'),
              ts: get_metadata('ts'),
            }
          })

          service = GithubIssueService.new(event: event)
          issue = service.issue_url(payload['actions'].first['selected_option']['value'],
                                    [],
                                    {'text' => Rails.cache.fetch(get_metadata('ts'), expires_in: 10.minutes) })

          b.section do |s|
            b.header(text: "Metadata")
            %w(ts channel).each do |n|
              b.section do |s|
                s.mrkdwn(text: "#{n}:#{get_metadata(n)}")
              end
            end
            b.divider
            s.plain_text(text: 'Click and open browser')
            s.button(text: 'OpenLink',
                     action_id: "submit",
                     url: issue.slice(0, 3000),
                     value: "create", emoji: true)
          end
        end
      end
    end

    modal = Slack::BlockKit.modal(title: "Create Issue", blocks: blocks)
    if payload['type'] == 'block_actions'
      client.views_update(trigger_id: payload['trigger_id'], view: modal.to_json, view_id: payload['view']['id'])
    else
      client.views_open(trigger_id: payload['trigger_id'], view: modal.to_json )
    end

    render status: 200, json: ""
  end

  def payload
    JSON.parse(params['payload'])
  end

  def get_metadata(key)
    a = payload['view']['blocks'].compact.find {|bl|
      bl['type'] == 'section' && bl['text']['type'] == 'mrkdwn' &&  bl['text']['text'] =~ /^#{key}:/
    }
    a['text']['text'].gsub(/#{key}:/, '')
  end
end
