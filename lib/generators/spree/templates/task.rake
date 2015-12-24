namespace :spree_<%=singular_name%> do
  desc 'Loads <%=singular_name%> sample data'
  task :load => :environment do
    Spree::Sample.load_sample("<%=plural_name%>")
  end
end