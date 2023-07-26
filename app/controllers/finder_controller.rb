class FinderController < ApplicationController
  before_action :authorize_request

  def search_info
    service = FinderService.new(item_params[:property], item_params[:work])
    report_service = ReportGeneratorService.new
    pdf = CombinePDF.new

    school_items = service.convenience(school_list)
    convenience_items = service.convenience(place_list)
    transport_data = service.transport

    summary_data = get_summary(school_items, convenience_items, transport_data)
    generate_summary(summary_data, report_service, pdf)
    generate_transport(transport_data, report_service, pdf)
    generate_school(school_items, report_service, pdf)
    generate_convenience(convenience_items, report_service, pdf)

    pdf.save 'public/combined_full.pdf'

    render plain: "#{request.base_url}/combined_full.pdf"
  end

  private

  def get_summary(school_items, convenience_items, _transport_data)
    qtd_escolas = school_items.first[:total_count]
    qtd_hospitais = convenience_items.find { |item| item[:name] == 'hospital' }[:total_count]
    qtd_academias = convenience_items.find { |item| item[:name] == 'academia' }[:total_count]
    qtd_drogarias = convenience_items.find { |item| item[:name] == 'drogaria' }[:total_count]
    qtd_shoppings = convenience_items.find { |item| item[:name] == 'shopping' }[:total_count]
    qtd_rests = convenience_items.find { |item| item[:name] == 'restaurante' }[:total_count]
    qtd_vets = convenience_items.find { |item| item[:name] == 'veterinario' }[:total_count]
    qtd_postos = convenience_items.find { |item| item[:name] == 'posto' }[:total_count]
    qtd_mercados = convenience_items.find { |item| item[:name] == 'mercado' }[:total_count]

    {
      qtd_escolas: qtd_escolas,
      qtd_hospitais: qtd_hospitais,
      qtd_academias: qtd_academias,
      qtd_drogarias: qtd_drogarias,
      qtd_shoppings: qtd_shoppings,
      qtd_rests: qtd_rests,
      qtd_vets: qtd_vets,
      qtd_postos: qtd_postos,
      qtd_mercados: qtd_mercados
    }
  end

  def generate_summary(data, report_service, pdf)
    odt_path = report_service.generate_summary(data)
    pdf_path = 'public/resumo'
    Libreconv.convert(odt_path, pdf_path)
    pdf << CombinePDF.load(pdf_path)
  end

  def generate_transport(data, report_service, pdf)
    odt_path = report_service.generate_transport(data)
    pdf_path = 'public/transport'
    Libreconv.convert(odt_path, pdf_path)
    pdf << CombinePDF.load(pdf_path)
  end

  def generate_convenience(data, report_service, pdf)
    data.each do |item|
      odt_path = report_service.generate(item)
      pdf_path = "public/#{item[:name]}"
      Libreconv.convert(odt_path, pdf_path)
      pdf << CombinePDF.load(pdf_path)
    end
  end

  def generate_school(data, report_service, pdf)
    school_main = data.find { |item| item[:name] == 'ensino_main' }
    odt_path = report_service.generate(school_main)
    pdf_path = "public/#{school_main[:name]}"
    Libreconv.convert(odt_path, pdf_path)
    pdf << CombinePDF.load(pdf_path)

    odt_path = report_service.generate_school(data)
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
        count: 5
      },
      {
        name: 'ensino_medio',
        keyword: 'ensino médio',
        type: 'school',
        count: 5
      },
      {
        name: 'ensino_superior',
        keyword: 'faculdade',
        type: 'university',
        count: 5
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
