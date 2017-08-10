module Spree
  class ScaffoldConfiguration < Preferences::Configuration
    preference :show_scaffold_menu, :boolean, :default => false
  end
end