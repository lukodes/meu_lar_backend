class FinderController < ApplicationController
  before_action :authorize_request

  def search_info
    service = FinderService.new(item_params[:property], item_params[:work])
    report_service = ReportGeneratorService.new
    pdf_service = PdfService.new

    school_items = service.convenience(PlaceConfig.school_list)
    convenience_items = service.convenience(PlaceConfig.place_list)
    transport_data = service.transport
    finance_data = service.calcula_financiamento_SAC(item_params[:property][:financial_value] || 220_000)

    summary_data = SummaryBuilder.build(school_items, convenience_items, transport_data)

    pdf_service.generate_combined_pdf(
      summary_data: summary_data,
      transport_data: transport_data,
      school_items: school_items,
      convenience_items: convenience_items,
      finance_data: finance_data,
      report_service: report_service
    )

    render plain: "#{request.base_url}/combined_full.pdf"
  end

  private

  def item_params
    params.permit(
      :customer_name,
      property: %i[
        zip_code
        district
        address
        address_number
        state
        city
        financial_value
        extra_info
      ],
      work: %i[
        zip_code
        district
        address
        address_number
        state
        city
        extra_info
      ]
    )
  end
end