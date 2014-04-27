module Pdftk

  # Represents a PDF
  class PDF
    attr_accessor :path

    def initialize path
      @path = path
    end

    def map_name name
      unless @_fields_mapping
        fields
      end
      @_fields_mapping[name]
    end
    
    def fields_with_values
      fields.reject {|field| field.value.nil? or field.value.empty? }
    end

    def clear_values
      fields_with_values.each {|field| field.value = nil }
    end

    def export output_pdf_path, extra_params=""
      xfdf_path = Tempfile.new('pdftk-xfdf').path
      File.open(xfdf_path, 'w'){|f| f << xfdf }
      system %{pdftk "#{path}" fill_form "#{xfdf_path}" output "#{output_pdf_path}" #{extra_params}}
    end

    def xfdf
      @fields = fields_with_values
      if @fields.any?
        haml_view_path = File.join File.dirname(__FILE__), 'xfdf.haml'
        eng = Haml::Engine.new(File.read(haml_view_path))
        eng.options.format = :xhtml
        eng.options.mime_type = 'text/xml'
        eng.render(self).to_s
      end
    end

    def fields
      unless @_all_fields
        field_output = `pdftk "#{path}" dump_data_fields`
        raw_fields   = field_output.split(/^---\n/).reject {|text| text.empty? }
        @_all_fields = raw_fields.map do |field_text|
          attributes = {}
          field_text.scan(/^(\w+): (.*)$/) do |key, value|
            attributes[key] = value
          end
          Field.new(attributes)
        end
        @_fields_mapping = Hash[@_all_fields.each_with_index.map{|field, index| [field.name,index]}]
      end
      @_all_fields
    end
  end

end
