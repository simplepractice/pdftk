module Pdftk
  # Represents a PDF
  class PDF
    TEMPLATE = File.read(File.join(File.dirname(__FILE__), "xfdf.erb"))

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
      fields.reject { |field| field.value.nil? or field.value.empty? }
    end

    def clear_values
      fields_with_values.each { |field| field.value = nil }
    end

    def export output_pdf_path, extra_params = ""
      Tempfile.create("pdftk-xfdf") do |file|
        file.write(xfdf)
        file.close

        run_cmd path, "fill_form", file.path, "output", output_pdf_path, extra_params
      end
    end

    def xfdf
      fields = fields_with_values
      if fields.any?
        eng = ERB.new(TEMPLATE)
        eng.result_with_hash(fields: fields)
      end
    end

    def fields
      unless @_all_fields
        field_output = run_cmd path, "dump_data_fields"
        raw_fields = field_output.split(/^---\n/).reject { |text| text.empty? }
        @_all_fields = raw_fields.map do |field_text|
          attributes = {}
          field_text.scan(/^(\w+): (.*)$/) do |key, value|
            attributes[key] = value
          end
          Field.new(attributes)
        end
        @_fields_mapping = @_all_fields.each_with_index.to_h { |field, index| [field.name, index] }
      end
      @_all_fields
    end

    private

    def run_cmd(*cmd)
      full_cmd = ["pdftk", *cmd.compact_blank.map(&:to_s)]
      stdout, stderr, status = Open3.capture3(*full_cmd)
      if status.success?
        stdout
      else
        raise Error, "Command #{full_cmd.join(" ")} returned non-zero exit status #{status.exitstatus}" \
                     "\n\n#{stderr.strip}"
      end
    end
  end
end
