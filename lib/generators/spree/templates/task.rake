namespace :spree_<%=singular_name%> do
  desc 'Loads <%=singular_name%> sample data'
  task :load => :environment do
    path = File.expand_path(File.join(Rails.root, 'db', 'samples', "<%=plural_name%>.rb"))
    if !$LOADED_FEATURES.include?(path)
      require path
      puts "Loaded <%=plural_name%> samples"
    end
  end
end