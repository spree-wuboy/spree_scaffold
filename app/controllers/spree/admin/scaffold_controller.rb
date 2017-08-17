module Spree
  module Admin
    class ScaffoldController < ResourceController
      include Spree::ScaffoldConcern
    end
  end
end