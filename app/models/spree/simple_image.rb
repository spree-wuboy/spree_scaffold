module Spree
  class SimpleImage < Spree::Base
    validate :no_attachment_errors
    attr_reader :attachment_remote_url

    def self.accepted_image_types
      %w(image/jpeg image/jpg image/png image/gif)
    end

    has_attached_file :attachment,
                      styles: { mini: '48x48>', small: '200x200>' , large: '1000x1000>'},
                      default_style: :large,
                      url: '/spree/images/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/images/:id/:style/:basename.:extension',
                      use_timestamp: false,
                      convert_options: { all: '-strip -auto-orient -colorspace sRGB -sampling-factor 4:2:0 -quality 80 -interlace JPEG' }

    validates_attachment :attachment,
                         presence: true,
                         content_type: { content_type: accepted_image_types }

    # save the w,h of the original image (from which others can be calculated)
    # we need to look at the write-queue for images which have not been saved yet
    before_save :find_dimensions, if: :attachment_updated_at_changed?

    # used by admin products autocomplete
    def mini_url
      attachment.url(:mini, false)
    end

    def attachment_remote_url=(url_value)
      self.attachment = URI.parse(url_value)
      # Assuming url_value is http://example.com/photos/face.png
      # avatar_file_name == "face.png"
      # avatar_content_type == "image/png"
      @avatar_attachment_url = url_value
    end

    def find_dimensions
      temporary = attachment.queued_for_write[:original]
      filename = temporary.path unless temporary.nil?
      filename = attachment.path if filename.blank?
      geometry = Paperclip::Geometry.from_file(filename)
      self.attachment_width  = geometry.width
      self.attachment_height = geometry.height
      data = File.read(filename)
      self.checksum = Digest::SHA2.hexdigest(data)
    end

    # if there are errors from the plugin, then add a more meaningful message
    def no_attachment_errors
      unless attachment.errors.empty?
        # uncomment this to get rid of the less-than-useful interim messages
        # errors.clear
        errors.add :attachment, "Paperclip returned errors for file '#{attachment_file_name}' - check ImageMagick installation or image source file."
        false
      end
    end

    def to_jq_upload
      {
          "name" => read_attribute(:attachment_file_name),
          "size" => read_attribute(:attachment_file_size),
          "url" => attachment.url(:large),
          "small_url" => attachment.url(:small),
          "mini_url" => attachment.url(:mini)
      }
    end
  end
end
