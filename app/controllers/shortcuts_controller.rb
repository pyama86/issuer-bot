class ShortcutsController < ApplicationController
  def create
    return render json: { "response_action": "clear" } if payload['type'] == 'block_actions' && payload['actions'].first['action_id'] == 'submit'
    blocks = Slack::BlockKit.blocks do |b|
      b.section do |s|
        s.plain_text(text: 'Chose Repository')
        s.static_select(placeholder: 'repo/org', action_id: "choice_repo", emoji: true) do |st|
          org_repos = Rails.cache.fetch("org_repos", expires_in: 60.minutes) do
            amonthago = Time.now - 86400 * 30
            octokit.organizations.map do |o|
              octokit.organization_repositories(o[:login]).select do |repo|
                amonthago < repo.updated_at
              end
            end.flatten.compact
          end

          cnt = 0

          org_hash = org_repos.each_with_object({}) do |o,r|
            ora =  o[:full_name].split('/')
            r[ora[0]] ||= []
            r[ora[0]]  << o[:full_name]
          end

          org_hash.each do |org,repos|
            st.option_group(label: org) do |og|
              repos.each do |r|
                i = payload['actions'].first['selected_option']['value'] == r rescue false
                og.option(value: r, text: r, emoji: true, initial: i)
              end
            end

            cnt += 1
            break if cnt > 5
          end
        end
      end

      case payload['type']
      when 'message_action'
        message = payload['message']
        b.divider
        b.header(text: "Metadata")
        b.section do |s|
          s.mrkdwn(text: "ts:#{payload['message']['ts']}")
        end
        b.section do |s|
          s.mrkdwn(text: "channel:#{payload['channel']['id']}")
        end
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
          issue = service.issue_url(payload['actions'].first['selected_option']['value'], [])

          b.section do |s|
            b.header(text: "Metadata")
            b.section do |s|
              s.mrkdwn(text: "ts:#{get_metadata('ts')}")
            end
            b.section do |s|
              s.mrkdwn(text: "channel:#{get_metadata('channel')}")
            end

            b.divider
            s.plain_text(text: 'Click and open browser')
            s.button(text: 'OpenLink',
                     action_id: "submit",
                     url: issue,
                     value: "create", emoji: true)
          end
        end
      end
    end

    modal = Slack::BlockKit.modal(title: "Create Issue", blocks: blocks)
    if payload['type'] == 'block_actions'
      client.views_update(trigger_id: payload['trigger_id'], view: modal.to_json.to_s, view_id: payload['view']['id'])
    else
      client.views_open(trigger_id: payload['trigger_id'], view: modal.to_json.to_s )
    end

    render :created
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
