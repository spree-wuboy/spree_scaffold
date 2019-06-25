module Spree
  module Api
    module V1
      class <%= class_name.pluralize %>Controller < Spree::Api::ResourceController
        # uncomment following if you need
        #skip_before_action :set_expiry
        #skip_before_action :check_for_user_or_api_key
        #skip_before_action :authenticate_user

        helper_method :<%=singular_name%>_attributes

        def create
          authorize! :create, Spree::<%=class_name%>
          @<%=singular_name%> = Spree::<%=class_name%>.new(map_nested_attributes_keys(Spree::<%=class_name%>, <%=singular_name%>_params))
          if @<%=singular_name%>.save
            respond_with(@<%=singular_name%>, :status => 201, :default_template => :show) do
              format.html { render layout: !request.xhr? }
              format.js   { render layout: false } if request.xhr?
            end
          else
            invalid_resource!(@<%=singular_name%>)
          end
        end

        def destroy
          authorize! :destroy, @<%=singular_name%>
          @<%=singular_name%>.destroy
          respond_with(@<%=singular_name%>, :status => 204) do
            format.html { render layout: !request.xhr? }
            format.js   { render layout: false } if request.xhr?
          end
        end

        def show
          respond_with(@<%=singular_name%>) do
            format.html { render layout: !request.xhr? }
            format.js   { render layout: false } if request.xhr?
          end
        end

        def update
          authorize! :update, @<%=singular_name%>
          if @<%=singular_name%>.update_attributes(map_nested_attributes_keys(Spree::<%=class_name%>, <%=singular_name%>_params))
            respond_with(@<%=singular_name%>, :status => 200, :default_template => :show) do
              format.html { render layout: !request.xhr? }
              format.js   { render layout: false } if request.xhr?
            end
          else
            invalid_resource!(@<%=singular_name%>)
          end
        end

        def <%=singular_name%>_attributes
            [
              :id,
            <%- attributes.each do |attribute| -%>
            <%- next unless attribute.name != "slug" -%>
              :<%=attribute.name%>,
                <%- end -%>
          ]
        end

        private

        def model_class
        <%- if options[:model_class] -%>
          @model_class = <%=options[:model_class]%>
        <%- else -%>
          @model_class = Spree::<%=class_name%>
        <%- end -%>
        end
      end
    end
  end
end