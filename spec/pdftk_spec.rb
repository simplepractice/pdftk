describe Pdftk::PDF do
  def path_to_pdf name
    File.join File.dirname(__FILE__), "pdfs", "#{name}.pdf"
  end

  describe "#fields" do
    before do
      @pdf = Pdftk::PDF.new path_to_pdf(:employment_application)
      @pdf.clear_values
    end

    it "can get total number of fields" do
      expect(@pdf.fields.length).to eq(125)
    end

    it "can get raw field attributes" do
      field = @pdf.fields.first
      expect(field.attributes.length).to eq(5)
      expect(field.attributes["FieldType"]).to eq("Text")
      expect(field.attributes["FieldName"]).to eq("First name")
      expect(field.attributes["FieldNameAlt"]).to eq("Please enter First Name here")
      expect(field.attributes["FieldFlags"]).to eq("0")
      expect(field.attributes["FieldJustification"]).to eq("Left")
    end

    it "can get field #name" do
      expect(@pdf.fields[0].name).to eq("First name")
      expect(@pdf.fields[1].name).to eq("Middle name")
      expect(@pdf.fields[2].name).to eq("Last name")
      expect(@pdf.fields[3].name).to eq("Street Address")
      expect(@pdf.fields[4].name).to eq("City")
    end

    it "can get field #type" do
      expect(@pdf.fields.map { |field| field.type }.uniq.sort).to eq(%w[Button Choice Text])
    end

    it "can set and get the #value that we want to set" do
      expect(@pdf.fields[3].value).to be_nil
      @pdf.fields[3].value = "Filled in with code"
      expect(@pdf.fields[3].value).to eq("Filled in with code")
    end

    it "can easily get all of the #fields_with_values" do
      @pdf.fields[3].value = "Filled in with code"
      expect(@pdf.fields_with_values.length).to eq(1)

      @pdf.fields[1].value = "Also Filled in with code"
      expect(@pdf.fields_with_values.length).to eq(2)

      @pdf.fields[1].value = "Changed the value of an already filled out field"
      expect(@pdf.fields_with_values.length).to eq(2)
    end

    it "can get the #xfdf that will be used to fill in the PDF" do
      expect(@pdf.xfdf).to be_nil

      @pdf.fields[0].value = "My Name"
      expect(@pdf.xfdf).to_not be_nil
      expect(@pdf.xfdf.squish).to eq(<<~XML.squish)
        <?xml version='1.0' encoding='utf-8' ?>
        <xfdf xml:space='preserve' xmlns='http://ns.adobe.com/xfdf/'>
          <fields>

            <field name='First name'>
              <value>My Name</value>
            </field>

          </fields>
        </xfdf>
      XML
    end

    it "can #export a PDF (with all of its values filled out)" do
      @pdf = Pdftk::PDF.new path_to_pdf(:employment_application)
      expect(@pdf.fields[0].value).to be_nil

      @pdf.fields[0].value = "Value set by code"
      tmp_path = Tempfile.new("pdftk-export-spec").path
      @pdf.export tmp_path

      expect(Pdftk::PDF.new(tmp_path).fields[0].value).to eq("Value set by code")
    end

    it "can #clear_values" do
      @pdf.fields[0].value = "First"
      @pdf.fields[1].value = "Middle"
      @pdf.fields[2].value = "Last"
      expect(@pdf.fields_with_values.length).to eq(3)

      @pdf.clear_values

      expect(@pdf.fields_with_values.length).to eq(0)
    end

    # it 'can get fields by type' do
    #  expect(@pdf.fields(:type => 'Text'  ).length).to eq(1)
    #  expect(@pdf.fields(:type => 'Button').length).to eq(1)
    #  expect(@pdf.fields(:type => 'Choice').length).to eq(1)
    # end

    # it 'can get field by name' do
    #  expect(@pdf.field('First name').name).to eq('First name')
    #  expect(@pdf.field(:City       ).name).to eq('City')
    # end
  end
end
