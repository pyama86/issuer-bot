class OrgRepoCacheJob < ApplicationJob
  queue_as :default
  def perform(*args)
    octokit = Octokit::Client.new(
      api_endpoint: ENV['GITHUB_API'] || 'api.github.com',
      access_token: ENV['GITHUB_TOKEN'],
      auto_paginate: true,
      per_page: 300
    )
    amonthago = Time.now - 86400 * 30
    r = octokit.organizations.map do |o|
          octokit.organization_repositories(o[:login], sort: 'updated', direction: 'desc').select do |repo|
          amonthago < repo.updated_at
        end
    end.flatten.compact
    Rails.cache.write("org_repos", r, expires_in: 60.minutes)
  end
end
