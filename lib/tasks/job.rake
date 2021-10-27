namespace :job do
  desc "Create org repo cache"
  task org_repo_cache: :environment do
    OrgRepoCacheJob.perform_now
  end
end
