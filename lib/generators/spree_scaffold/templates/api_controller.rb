module Spree
  module Api
    module V1
      class <%= class_name.pluralize %>Controller < Spree::Api::Core::V1::<%= class_name.pluralize %>Controller
      end
    end
  end
end