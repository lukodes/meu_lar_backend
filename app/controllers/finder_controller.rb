
class FinderController < ApplicationController
  # before_action :authorize_request

  def search_info
    template_path = File.join(Rails.root, "app", "assets", "templates")
    service = FinderService.new(item_params[:property][:zip_code])

    # - Transporte
    # - Mercados

    result = service.ensino
    path = File.join(template_path, "ensino.odt")
    download_url = ReportGeneratorService.new(path, result).ensino
    Libreconv.convert(download_url, 'public/ensino.pdf')

    result = service.ensino2
    path = File.join(template_path, "ensino2.odt")
    download_url = ReportGeneratorService.new(path, result).ensino2
    Libreconv.convert(download_url, 'public/ensino2.pdf')

    result = service.drogaria
    path = File.join(template_path, "drogaria.odt")
    download_url = ReportGeneratorService.new(path, result).drogaria
    Libreconv.convert(download_url, 'public/drogaria.pdf')

    result = service.hospital
    path = File.join(template_path, "hospital.odt")
    download_url = ReportGeneratorService.new(path, result).hospital
    Libreconv.convert(download_url, 'public/hospital.pdf')

    result = service.academia
    path = File.join(template_path, "academia.odt")
    download_url = ReportGeneratorService.new(path, result).academia
    Libreconv.convert(download_url, 'public/academia.pdf')

    result = service.posto
    path = File.join(template_path, "posto.odt")
    download_url = ReportGeneratorService.new(path, result).posto
    Libreconv.convert(download_url, 'public/posto.pdf')

    result = service.veterinario
    path = File.join(template_path, "veterinario.odt")
    download_url = ReportGeneratorService.new(path, result).veterinario
    Libreconv.convert(download_url, 'public/veterinario.pdf')

    result = service.restaurante
    path = File.join(template_path, "restaurante.odt")
    download_url = ReportGeneratorService.new(path, result).restaurante
    Libreconv.convert(download_url, 'public/restaurante.pdf')

    result = service.shopping
    path = File.join(template_path, "shopping.odt")
    download_url = ReportGeneratorService.new(path, result).shopping
    Libreconv.convert(download_url, 'public/shopping.pdf')

    pdf = CombinePDF.new
    pdf << CombinePDF.load("public/ensino.pdf") # one way to combine, very fast.
    pdf << CombinePDF.load("public/ensino2.pdf")
    pdf << CombinePDF.load("public/drogaria.pdf")
    pdf << CombinePDF.load("public/hospital.pdf")
    pdf << CombinePDF.load("public/academia.pdf")
    pdf << CombinePDF.load("public/posto.pdf")
    pdf << CombinePDF.load("public/veterinario.pdf")
    pdf << CombinePDF.load("public/restaurante.pdf")
    pdf << CombinePDF.load("public/shopping.pdf")

    pdf.save "public/combined_full.pdf"
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
