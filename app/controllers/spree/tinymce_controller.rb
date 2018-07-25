module Spree
  class TinymceController < BaseController
    protect_from_forgery
    layout 'spree/layouts/tinymce'

    def insert
    end

    def upload
      images = []
      params.to_unsafe_h[:images][0].each do |key, image|
        data = File.read(image.path)
        checksum = Digest::SHA2.hexdigest(data)
        exist_image = Spree::SimpleImage.where(:checksum => checksum).first
        if exist_image
          images.push(exist_image)
        else
          images.push(Spree::SimpleImage.create!({
                                               :attachment => image,
                                               :checksum => checksum
                                           }))
        end
      end if params[:images] && params.to_unsafe_h[:images][0]

      if params[:urls]
        urls = params[:urls].gsub("\r", "").split("\n")
        urls.each do |url|
          if remote_image_exists?(url)
            images.push(Spree::SimpleImage.create!({
                                                       :attachment => URI.parse(url)
                                                   }))
          end
        end
      end

      respond_to do |format|
        format.html {
          render :json => images.map { |i| "#{request.url}#{i.attachment.url}" }.to_json
        }
        format.js {
          render :json => images.map { |i| i.to_jq_upload }
        }
        format.json {
          render :json => images.map { |i| i.to_jq_upload }
        }
      end
    end

    def remote_image_exists?(url)
      url = URI.parse(url)
      Net::HTTP.start(url.host, url.port) do |http|
        return http.head(url.request_uri)['Content-Type'].start_with? 'image'
      end
    end
  end
end