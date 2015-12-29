module Spree
  module Admin
    class <%= class_name.pluralize %>Controller < ResourceController
      helper_method :batch_url, :check_all_url
      respond_to :html, :json, :pdf
      include ::PdfHelper
      helper ::WickedPdfHelper::Assets

      before_action :add_edit_fk, only: [:edit, :new, :update, :create]
      before_action :add_search_fk, only: :index

      def index
        respond_with(@collection) do |format|
          format.html
          format.pdf do
            render_with_wicked_pdf :pdf => Time.now.to_i.to_s, :show_as_html => params[:debug]
          end
        end
      end

      def batch
        collection
        respond_with(@collection) do |format|
          format.html
          format.pdf do
            render_with_wicked_pdf :pdf => Time.now.to_i.to_s, :show_as_html => params[:debug]
          end
        end
      end

      def check_all
        session[:ids] ||= []
        @collection = collection
        ids = @collection.pluck(:id)
        if params[:checked] == "all"
          session[:ids] = []
        elsif params[:checked] == "true"
          session[:ids] = (session[:ids] + ids).uniq
        else
          session[:ids] = (session[:ids] - ids).uniq
        end
        render :js => "window.location = '#{collection_url(:q => params[:q], :page => params[:page], :per_page => params[:per_page])}'"
      end

      def show
        respond_with(@object) do |format|
          format.html
          format.pdf do
            render_with_wicked_pdf :pdf => "<%=singular_name%>_#{@object.id}", :show_as_html => params[:debug]
          end
        end
      end

      def check
        session[:ids] ||= []
        if params[:checked] == "true"
          session[:ids].push(params[:id].to_i)
          render :nothing => true
        else
          session[:ids].delete(params[:id].to_i)
          render :js => "document.getElementById('check_all').checked = false"
        end
      end

      def collection
        return @collection if @collection.present?
        params[:q] ||= {}
        search_checked = params[:q].delete(:search_checked)
        @collection = super
        @collection.includes(<%=options[:fk].keys.map{|fk| fk.to_sym}%>)
        if search_checked == "true"
          @search = @collection.ransack(params[:q].merge(:id_in => session[:ids]))
          params[:q][:search_checked] = true
        else
          @search = @collection.ransack(params[:q])
          params[:q][:search_checked] = false
        end
        if params[:format] == :pdf
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

      def check_all_url(options = {})
        check_all_admin_<%=plural_name%>_url(options)
      end

      private

      def add_edit_fk
<% attributes.each do |attribute| -%>
<% if options[:fk].values.include?(attribute.name) -%>
<% fk_class_name = "Spree::#{options[:fk].invert[attribute.name].camelcase}" -%>
        if defined?(<%=fk_class_name%>)
          @select_<%=attribute.name%> = <%=fk_class_name%>.all
        end
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
