class FinderController < ApplicationController
  before_action :authorize_request

  def search_info
    service = FinderService.new(item_params[:property], item_params[:work])
    report_service = ReportGeneratorService.new
    pdf = CombinePDF.new

    generate_transport(service, report_service, pdf)
    generate_school(service, report_service, pdf)
    generate_convenience(service, report_service, pdf)

    pdf.save 'public/combined_full.pdf'

    render plain: "#{request.base_url}/combined_full.pdf"
  end

  private

  def generate_transport(service, report_service, pdf)
    transport_data = service.transport
    odt_path = report_service.generate_transport(transport_data)
    pdf_path = 'public/transport'
    Libreconv.convert(odt_path, pdf_path)
    pdf << CombinePDF.load(pdf_path)
  end

  def generate_convenience(service, report_service, pdf)
    convenience_items = service.convenience(place_list)
    convenience_items.each do |item|
      odt_path = report_service.generate(item)
      pdf_path = "public/#{item[:name]}"
      Libreconv.convert(odt_path, pdf_path)
      pdf << CombinePDF.load(pdf_path)
    end
  end

  def generate_school(service, report_service, pdf)
    school_items = service.convenience(school_list)
    school_main = school_items.find { |item| item[:name] == 'ensino_main' }
    odt_path = report_service.generate(school_main)
    pdf_path = "public/#{school_main[:name]}"
    Libreconv.convert(odt_path, pdf_path)
    pdf << CombinePDF.load(pdf_path)

    odt_path = report_service.generate_school(school_items)
    pdf_path = 'public/school'
    Libreconv.convert(odt_path, pdf_path)
    pdf << CombinePDF.load(pdf_path)
  end

  def place_list
    [
      {
        name: 'academia',
        keyword: 'academia',
        type: 'gym',
        count: 7
      },
      {
        name: 'drogaria',
        keyword: 'farmácia',
        type: 'pharmacy',
        count: 12
      },
      {
        name: 'shopping',
        keyword: 'shopping',
        type: 'shopping_mall',
        count: 7
      },
      {
        name: 'restaurante',
        keyword: 'restaurante',
        type: 'restaurant',
        count: 7
      },
      {
        name: 'veterinario',
        keyword: 'veterinario',
        type: 'veterinary_care',
        count: 7
      },
      {
        name: 'posto',
        keyword: 'posto de gasolina',
        type: 'gas_station',
        count: 7
      },
      {
        name: 'mercado',
        keyword: 'mercado',
        type: 'supermarket',
        count: 11
      },
      {
        name: 'hospital',
        keyword: 'hospital',
        type: 'hospital',
        count: 7
      }
    ].freeze
  end

  def school_list
    [
      {
        name: 'ensino_main',
        keyword: 'berçario',
        type: 'school',
        count: 7
      },
      {
        name: 'ensino_fundamental',
        keyword: 'ensino fundamental',
        type: 'school',
        count: 5,
      },
      {
        name: 'ensino_medio',
        keyword: 'ensino médio',
        type: 'school',
        count: 5,
      },
      {
        name: 'ensino_superior',
        keyword: 'faculdade',
        type: 'university',
        count: 5,
      }
    ]
  end

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
