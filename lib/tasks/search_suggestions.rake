namespace :search_suggestions do
  desc "Generate search suggestions for Champions"
  task :index => :environment do
    SearchSuggestion.index_champions
  end
end
