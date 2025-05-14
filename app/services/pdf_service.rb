class PdfService
  def generate_combined_pdf(summary_data:, transport_data:, school_items:, convenience_items:, finance_data:,
                            report_service:)
    pdf = CombinePDF.new

    append_pdf(pdf, report_service.generate_summary(summary_data), 'resumo')
    append_pdf(pdf, report_service.generate_transport(transport_data), 'transport')
    append_pdf(pdf, report_service.generate_school(school_items), 'school')
    append_convenience_pdfs(pdf, convenience_items, report_service)
    append_pdf(pdf, report_service.generate_finance(finance_data), 'financiamento')

    pdf.save 'public/combined_full.pdf'
  end

  private

  def append_pdf(pdf, odt_path, pdf_basename)
    pdf_path = "public/#{pdf_basename}.pdf"
    system("/snap/bin/libreoffice --headless --convert-to pdf \"#{odt_path}\" --outdir public")
    File.rename("public/#{File.basename(odt_path, '.*')}.pdf", pdf_path) if File.exist?("public/#{File.basename(
      odt_path, '.*'
    )}.pdf")
    raise "PDF file not found: #{pdf_path}" unless File.exist?(pdf_path)

    pdf << CombinePDF.load(pdf_path)
    File.delete(pdf_path) if File.exist?(pdf_path)
  end

  def append_convenience_pdfs(pdf, convenience_items, report_service)
    convenience_items.each do |item|
      append_pdf(pdf, report_service.generate(item), "#{item[:name]}")
    end
  end
end
