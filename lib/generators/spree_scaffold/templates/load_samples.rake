namespace :spree do
  namespace :load_samples do
    desc 'Loads sample data'
    task :load => :environment do
      puts "Loaded samples"
    end
  end
end