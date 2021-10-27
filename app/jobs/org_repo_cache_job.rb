class OrgRepoCacheJob < ApplicationJob
  queue_as :default
  def perform(*args)
    Rails.cache.write("org_repos", GithubRepos.often_use_repos, expires_in: 60.minutes)
  end
end
