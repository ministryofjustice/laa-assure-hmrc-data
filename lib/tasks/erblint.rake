desc "Run ERB lint"
task erb_lint: :environment do
  path = "app/views"
  sh("erb_lint #{path}")
end
