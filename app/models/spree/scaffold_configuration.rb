module Spree
  class ScaffoldConfiguration < Preferences::Configuration
    preference :show_scaffold_menu, :boolean, :default => false
    preference :per_page, :integer, :default => 30
  end
end