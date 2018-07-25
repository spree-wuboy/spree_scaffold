module Spree
  module Admin
    class SimpleImagesController < ScaffoldController
      skip_before_action :verify_authenticity_token

      def publish
        images = []
        params[:images].each do |image|
          checksum = Digest::SHA2.hexdigest(image.read)
          exist_image = Spree::SimpleImage.where(:checksum => checksum).first
          if exist_image
            images.push(exist_image)
          else
            images.push(Spree::SimpleImage.create!({
                                                       :attachment => image,
                                                       :checksum => checksum
                                                   }))
          end
        end if params[:images]

        respond_to do |format|
          format.html {
            render :json => images.map {|i| "#{request.url}#{i.attachment.url}"}.to_json
          }
          format.js {
            render :json => images.map {|i| i.to_jq_upload}
          }
          format.json {
            render :json => images.map {|i| i.to_jq_upload}
          }
        end
      end
    end
  end
end