# frozen_string_literal: true

class GithubRepos
  include ActiveModel::Model
  def self.octokit
    @_octokit ||= Octokit::Client.new(
      api_endpoint: ENV['GITHUB_API'] || 'api.github.com',
      access_token: ENV['GITHUB_TOKEN'],
      auto_paginate: true,
      per_page: 300
    )
  end

  def self.often_use_repos
    amonthago = Time.now - 86_400 * 30
    octokit.organizations.map do |o|
      octokit.organization_repositories(o[:login], sort: 'updated', direction: 'desc').select do |repo|
        amonthago < repo.updated_at
      end
    end.flatten.compact.sort_by!(&:updated_at).reverse.each_with_object({}) do |o, r|
      ora = o[:full_name].split('/')
      r[ora[0]] ||= []
      r[ora[0]] << o[:full_name]
    end
  end
end
