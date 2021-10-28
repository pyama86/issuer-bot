class ShortcutsController < ApplicationController
  def options
    org_hash = Rails.cache.fetch("org_repos", expires_in: 60.minutes) do
      GithubRepos.often_use_repos
    end

    ogs = org_hash.map do |org,repos|
      Slack::BlockKit::Composition::OptionGroup.new(label: org) do |og|
        repos.each_with_index do |r,index|
          next if payload['type'] == 'block_suggestion' && r !~ /#{payload['value']}/
          og.option(value: r, text: r, emoji: true) if index < 100
        end
      end
    end.select do |og|
      og.options.size > 0
    end
    render  json: { option_groups: ogs.map(&:as_json) }.to_json
  end

  def create
    should_add_submit = false
    init_opt = begin
                 v = payload['actions'].first['selected_option']['value']
                 Slack::BlockKit::Composition::Option.new(value: v, text: v, emoji: true)
               rescue
                 nil
               end
    blocks = Slack::BlockKit.blocks do |b|
      b.section do |s|
        s.plain_text(text: 'Chose Repository')
        s.external_select(placeholder: 'repo/org', action_id: "choice_repo", emoji: true, initial: init_opt)
      end

      case payload['type']
      when 'view_submission'
          event = {
            item: {
              channel: get_metadata('channel'),
              ts: get_metadata('ts'),
            }
          }
          channel = {
            org_repo: payload['view']['state']['values'].first[1]['choice_repo']['selected_option']['value'],
            labels: []
          }
          CreateIssuerJob.perform_later(channel, event)
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
          b.header(text: "Metadata")
          %w(ts channel).each do |n|
            b.section do |s|
              s.mrkdwn(text: "#{n}:#{get_metadata(n)}")
            end
          end
          should_add_submit = true
        end
      end
    end

    modal = Slack::BlockKit.modal(title: "Create Issue", blocks: blocks)

    modal.submit(text: "Send link", emoji: true) if should_add_submit

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
