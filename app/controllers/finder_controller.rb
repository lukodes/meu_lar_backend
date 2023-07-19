
class FinderController < ApplicationController
  # before_action :authorize_request

  def search_info
    template_path = File.join(Rails.root, "app", "assets", "templates")
    service = FinderService.new(item_params[:property][:zip_code])
    result = service.ensino
    path = File.join(template_path, "ensino.odt")
    download_url = ReportGeneratorService.new(path, result).ensino
    Libreconv.convert(download_url, 'public/ensino.pdf')

    result = service.ensino2
    path = File.join(template_path, "ensino2.odt")
    download_url = ReportGeneratorService.new(path, result).ensino2
    Libreconv.convert(download_url, 'public/ensino2.pdf')
    pdf = CombinePDF.new
    pdf << CombinePDF.load("public/ensino.pdf") # one way to combine, very fast.
    pdf << CombinePDF.load("public/ensino2.pdf")
    pdf.save "public/combined.pdf"
    render json: download_url, status: :ok
  end

  private

  def item_params
    params.permit(
      :customer_name,
      property: [
        :zip_code,
        :address,
        :address_number,
        :state,
        :city,
        :extra_info
      ],
      related_addresses: [
        :zip_code,
        :address,
        :address_number,
        :state,
        :city,
        :extra_info
      ]
    )
  end
end
