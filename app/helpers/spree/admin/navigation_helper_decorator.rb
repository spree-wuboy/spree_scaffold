module Spree
  module Admin
    NavigationHelper.module_eval do

      # the per_page_dropdown is used on index pages like orders, products, promotions etc.
      # this method generates the select_tag
      def per_page_dropdown
        # there is a config setting for admin_products_per_page, only for the orders page
        per_page_options = []
        if @products
          per_page_default = Spree::Config.admin_products_per_page
        elsif @orders && per_page_default = Spree::Config.admin_orders_per_page
          per_page_default = Spree::Config.admin_orders_per_page
        else
          per_page_default = SpreeScaffold::Config[:per_page]
        end
        10.times do |amount|
          per_page_options << (amount + 1) * per_page_default
        end

        selected_option = params[:per_page].try(:to_i) || per_page_default

        select_tag(:per_page,
                   options_for_select(per_page_options, selected_option),
                   class: "form-control pull-right js-per-page-select per-page-selected-#{selected_option}")
      end
    end
  end
end
