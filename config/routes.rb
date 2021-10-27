Rails.application.routes.draw do
  post 'register', to: 'reactions#register'
  post 'deregister', to: 'reactions#deregister'
  post 'list', to: 'reactions#list'

  constraints Constraint::SlackEvent.new(:reaction_added) do
    post 'events', to: 'reactions#added'
  end

  constraints Constraint::SlackEvent.new(:url_verification) do
    post 'events', to: 'reactions#challenge'
  end
end
