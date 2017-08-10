module Spree
  module Admin
    class <%= class_name.pluralize %>Controller < ResourceController
      helper_method :batch_url, :batch_check_url, :add_check_url, :checks, :checks=
      respond_to :html, :json, :pdf
      include ::PdfHelper
      helper ::WickedPdfHelper::Assets

      before_action :add_edit_fk, only: [:edit, :new, :update, :create]
      before_action :add_search_fk, only: :index
      before_action :init_checked

      def new
      <%- options[:nested].each do |nested| -%>
          @object.<%=nested%>.build
      <%- end -%>
      end

      def edit
      <%- options[:nested].each do |nested| -%>
        @object.<%=nested%>.build
      <%- end -%>
      end

      def index
        respond_to do |format|
          format.html
          format.pdf do
            render_with_wicked_pdf :pdf => "<%=plural_name%>_#{Time.now.to_i.to_s}",
                                   :show_as_html => params[:debug],
                                   :layout => "spree/layouts/pdf.pdf"
          end
          format.csv {
            data = @collection.to_csv({}, params.to_unsafe_h)
            require 'iconv'
            data = Iconv.new("big5//IGNORE", "utf-8").iconv(data) #remove this if you won't use excel to open csv in traditional Chinese
            send_data data, :filename => "<%=plural_name%>_#{Time.now.to_i.to_s}.csv",
                      :disposition => 'inline', :type => "text/csv"
          }
        end
      end

      def batch
        collection
        respond_to do |format|
          format.html
          format.pdf do
            render_with_wicked_pdf :pdf => "<%=plural_name%>_#{@collection.size}_#{Time.now.to_i.to_s}",
                                   :show_as_html => params[:debug],
                                   :layout => "layouts/pdf.pdf"
          end
        end
      end

      def batch_checked
        if params[:all].present?
          if params[:all] == "true"
            session[:<%=plural_name%>_checked] = collection.pluck(:id)
          elsif params[:all] == "reverse"
            collection.pluck(:id).each do |id|
              session[:<%=plural_name%>_checked].include?(id) ? session[:<%=plural_name%>_checked].delete(id) : session[:<%=plural_name%>_checked].push(id)
            end
          elsif params[:all] == "false"
            session[:<%=plural_name%>_checked] = []
          end
        end
        params.delete(:all)
        redirect_to collection_url(:params => params.to_unsafe_h)
      end

      def add_checked
        if params[:checked] && params[:checked] == "true"
          session[:<%=plural_name%>_checked].push(@object.id) unless session[:<%=plural_name%>_checked].include?(@object.id)
        else
          session[:<%=plural_name%>_checked].delete(@object.id) if session[:<%=plural_name%>_checked].include?(@object.id)
        end
        render :nothing => true
      end

      def show
        respond_to do |format|
          format.html
          format.pdf do
            render_with_wicked_pdf :pdf => "<%=singular_name%>_#{@object.id}", :show_as_html => params[:debug]
          end
        end
      end

      def seacher
        params[:q] ||= {}
        if !params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end

        if !params[:q][:created_at_lt].blank?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end
        base_search = method(:collection).super_method.call
        base_search.includes(<%=options[:fk].keys.map{|fk| fk.to_sym}%>)
        if params[:q][:checked] == "true"
          base_search.ransack(params[:q].merge(:id_in => session[:<%=plural_name%>_checked]))
        else
          base_search.ransack(params[:q])
        end
      end

      def collection
        return @collection if @collection.present?
        @search = seacher
        if (params[:format] == "pdf" || params[:format] == "csv")
          @collection = @search.result(distinct: true)
        else
          @collection = @search.result(distinct: true).
              page(params[:page]).
              per(params[:per_page] || 30)
        end
        @collection
      end

      def batch_url(options = {})
        batch_admin_<%=plural_name%>_url(options)
      end

      def batch_check_url(options = {})
        batch_checked_admin_<%=plural_name%>_url(options)
      end

      def add_check_url(options = {})
        add_checked_admin_<%= singular_name %>_url(options)
      end

      def checks
        session[:<%=plural_name%>_checked] ||= []
      end

      def checks=chs
        session[:<%=plural_name%>_checked] = chs
      end

      private

      def init_checked
        session[:<%=plural_name%>_checked] ||= []
      end

      def add_edit_fk
<% attributes.each do |attribute| -%>
<% if options[:fk].values.include?(attribute.name) -%>
<% fk_class_name = "Spree::#{options[:fk].invert[attribute.name].camelcase}" -%>
        if defined?(<%=fk_class_name%>)
          @select_<%=attribute.name%> = <%=fk_class_name%>.all
        end
<% elsif attribute.type == :polymorphic -%>
          @select_<%=attribute.name%>_id = @object.present? && @object.<%=attribute.name%>_type.present? ? @object.<%=attribute.name%>_type.constantize.all : []
<% end -%>
<% end -%>
      end

      def add_search_fk
<% options[:search].each do |column| -%>
<% if options[:fk].values.include?(column) -%>
<% fk_class_name = "Spree::#{options[:fk].invert[column].camelcase}" -%>
        if defined?(<%=fk_class_name%>)
          @search_<%=column%> = <%=fk_class_name%>.all
        end
<% end -%>
<% end -%>
      end
    end
  end
end
