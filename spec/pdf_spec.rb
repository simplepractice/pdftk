describe Pdftk::PDF do
  let(:pdf_name) { "employment_application.pdf" }
  let(:pdf) do
    pdf = Pdftk::PDF.new File.join File.dirname(__FILE__), "pdfs", pdf_name
    pdf.clear_values
    pdf
  end

  describe "#fields" do
    it "can get total number of fields" do
      expect(pdf.fields.length).to eq(125)
    end

    it "can get raw field attributes" do
      field = pdf.fields.first
      expect(field.attributes.length).to eq(5)
      expect(field.attributes["FieldType"]).to eq("Text")
      expect(field.attributes["FieldName"]).to eq("First name")
      expect(field.attributes["FieldNameAlt"]).to eq("Please enter First Name here")
      expect(field.attributes["FieldFlags"]).to eq("0")
      expect(field.attributes["FieldJustification"]).to eq("Left")
    end

    it "can get field #name" do
      expect(pdf.fields[0].name).to eq("First name")
      expect(pdf.fields[1].name).to eq("Middle name")
      expect(pdf.fields[2].name).to eq("Last name")
      expect(pdf.fields[3].name).to eq("Street Address")
      expect(pdf.fields[4].name).to eq("City")
    end

    it "can get field #type" do
      expect(pdf.fields.map { |field| field.type }.uniq.sort).to eq(%w[Button Choice Text])
    end

    it "can set and get the #value that we want to set" do
      expect(pdf.fields[3].value).to be_nil
      pdf.fields[3].value = "Filled in with code"
      expect(pdf.fields[3].value).to eq("Filled in with code")
    end

    it "can easily get all of the #fields_with_values" do
      pdf.fields[3].value = "Filled in with code"
      expect(pdf.fields_with_values.length).to eq(1)

      pdf.fields[1].value = "Also Filled in with code"
      expect(pdf.fields_with_values.length).to eq(2)

      pdf.fields[1].value = "Changed the value of an already filled out field"
      expect(pdf.fields_with_values.length).to eq(2)
    end

    context "incorrect input file" do
      let(:pdf_name) { "404.pdf" }

      it "can raise error" do
        expect { pdf.fields }.to raise_error(Pdftk::Error) do |err|
          expect(err.message).to include("returned non-zero exit status 1")
          expect(err.message).to include("Error: Unable to find file")
        end
      end
    end
  end

  describe "#xfdf" do
    it "can get the xfdf that will be used to fill in the PDF" do
      expect(pdf.xfdf).to be_nil

      pdf.fields[0].value = "My Name"
      pdf.fields[1].value = "<lol&wat'>"
      expect(pdf.xfdf).to_not be_nil
      expect(pdf.xfdf.squish).to eq(<<~XML.squish)
        <?xml version='1.0' encoding='utf-8' ?>
        <xfdf xml:space='preserve' xmlns='http://ns.adobe.com/xfdf/'>
          <fields>

            <field name='First name'>
              <value>My Name</value>
            </field>

            <field name='Middle name'>
              <value>&lt;lol&amp;wat&#39;&gt;</value>
            </field>

          </fields>
        </xfdf>
      XML
    end
  end

  describe "#clear_values" do
    it "can clear_values" do
      pdf.fields[0].value = "First"
      pdf.fields[1].value = "Middle"
      pdf.fields[2].value = "Last"
      expect(pdf.fields_with_values.length).to eq(3)

      pdf.clear_values

      expect(pdf.fields_with_values.length).to eq(0)
    end
  end

  describe "#export" do
    let(:tmp_path) { Tempfile.new("pdftk-export-spec").path }

    it "can export a PDF (with all of its values filled out)" do
      expect(pdf.fields[0].value).to be_nil

      pdf.fields[0].value = "Value set by code"
      pdf.export tmp_path

      expect(Pdftk::PDF.new(tmp_path).fields[0].value).to eq("Value set by code")
    end

    context "empty fields" do
      it "can raise error" do
        expect { pdf.export tmp_path }.to raise_error(Pdftk::Error) do |err|
          expect(err.message).to include("returned non-zero exit status 1")
          expect(err.message).to include("Error: Failed to open form data file")
        end
      end
    end
  end
end
