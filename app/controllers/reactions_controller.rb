class ReactionsController < ApplicationController
  def list
    cs = Channel.where(
      slack_channel_id: params["channel_id"],
    )

    return render plain: "##{params["channel_name"]}はリアクション登録がありません", status: 200 unless cs.present?

    ret = cs.map do |c|
      "リアクション :#{c.reaction_id}: リポジトリ: #{c.org_repo} ラベル:#{c.labels}"
    end
    render plain: ret.join("\n"), status: 200
  end

  def register
    cm = params["text"].match(/(?<reaction>[^\b\s]+)[\b\s]+(?<org>[^\s\b]+)\/(?<repo>[^\s\b]+)[\b\s]?(?<labels>[^\s\b]+)?$/)
    return "パラメーターが不正です" unless cm
    reaction = cm["reaction"].delete(":")

    c = Channel.where(
      slack_channel_id: params["channel_id"],
      reaction_id: reaction,
    ).first_or_initialize(
      org_repo: "#{cm["org"]}/#{cm["repo"]}",
      labels: cm["labels"]
    )

    text = if c.new_record?
      c.save!
      "##{params["channel_name"]}でリアクション :#{reaction}: が実行された場合に、 #{cm["org"]}/#{cm["repo"]} にissueを作成します"
    else
      "既に同じリアクションで登録済みです"
    end

    render plain: text, status: 200
  end

  def deregister
    cm = params["text"].match(/(?<reaction>[^\b\s]+)[\b\s]+(?<org>[^\s\b]+)\/(?<repo>[^\s\b]+)$/)
    return render plain: "パラメーターが不正です", status: 200 unless cm
    reaction = cm["reaction"].delete(":")

    Channel.where(
      slack_channel_id: params["channel_id"],
      reaction_id: reaction,
    ).delete_all

    render plain: "##{params["channel_name"]}のリアクション :#{cm["reaction"]}: 登録を削除しました", status: 200
  end

  def added
    c = Channel.where(
      slack_channel_id: event.item.channel,
      reaction_id: event.reaction,
    ).first

    if c
      service = GithubIssueService.new(event: event)
      issue   = service.create_issue!(c.org_repo, c.labels)
      text    = "%s にissueを作成しました。" % issue.html_url
      client.chat_postMessage(text: text, channel: event.item.channel)
    end
    render json: { ok: true }, status: 200
  end

  def challenge
    render plain: params[:challenge], status: 200
  end
end
