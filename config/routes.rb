Rails.application.routes.draw do
  post 'register', to: 'reactions#register'
  post 'deregister', to: 'reactions#deregister'
  post 'list', to: 'reactions#list'

  constraints Constraint::SlackEvent.new(:reaction_added) do
    post 'slack/event-endpoint', to: 'reactions#added'
  end

  constraints Constraint::SlackEvent.new(:url_verification) do
    post 'slack/event-endpoint', to: 'reactions#challenge'
  end
end
