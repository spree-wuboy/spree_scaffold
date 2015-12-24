require 'wicked_pdf'
WickedPdf.config = {
  #:wkhtmltopdf => '/usr/local/bin/wkhtmltopdf',
  #:layout => "pdf.html",
  :exe_path => "#{Gem.loaded_specs['wkhtmltopdf-binary'].full_gem_path}/bin/wkhtmltopdf"
}

Mime::Type.register "application/pdf", :pdf unless Mime::Type.lookup_by_extension(:pdf)