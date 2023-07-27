include ActionView::Helpers::NumberHelper

class FinderService < ApplicationService
  MIN_RATING = 5
  def initialize(property, work)
    @client = GooglePlaces::Client.new(Settings.google_places_api_key)
    @gmaps = GoogleMapsService::Client.new
    @property_cordinates = Geocoder.search("postal_code: #{property[:zip_code]} | number: #{property[:address_number]}").first.coordinates
    @work_cordinates = Geocoder.search("postal_code: #{work[:zip_code]} | number: #{work[:address_number]}").first.coordinates
    @property = property
    @work = work
  end

  def convenience(place_list)
    result_items = []
    place_list.each do |place|
      result_items << get_data(place)
    end
    result_items
  end

  def transport
    date = Date.tomorrow
    dia_util = date.next_weekday
    peak_time = DateTime.new(dia_util.year, dia_util.month, dia_util.day, 11, 0, 0) # 8 horas da manhã

    directions = @gmaps.directions(
      "#{@property_cordinates[0]},#{@property_cordinates[1]}",
      "#{@work_cordinates[0]},#{@work_cordinates[1]}",
      mode: 'driving',
      departure_time: peak_time,
      language: 'pt-BR'
    )

    origin = "#{@property[:address]}, #{@property[:address_number]} - #{@property[:district]}, #{@property[:city]} - #{@property[:state]}, #{@property[:zip_code]}"
    destination = "#{@work[:address]}, #{@work[:address_number]} - #{@work[:district]}, #{@work[:city]} - #{@work[:state]}, #{@work[:zip_code]}"
    directions_public = @gmaps.directions(
      origin,
      destination,
      mode: 'transit',
      departure_time: peak_time,
      language: 'pt-BR'
    )

    instructions_public = []
    directions_public[0][:legs][0][:steps].each_with_index do |step, index|
      instructions_public << { index: index, instruction: step[:html_instructions], distance: step[:distance][:text] }
    end

    duration_peak = directions[0][:legs][0][:duration_in_traffic][:text]
    duration_nopeak = directions[0][:legs][0][:duration][:text]
    work_distance = directions[0][:legs][0][:distance][:text]

    {
      work_distance: work_distance,
      duration_peak: duration_peak,
      duration_nopeak: duration_nopeak,
      instructions_public: instructions_public
    }
  end

  def calcula_financiamento_SAC(valor_imovel)
    # Configurações
    percentual_renda = 0.30
    percentual_entrada = 0.20
    taxa_juros = 0.11
    meses = 420

    # Calcula os valores
    valor_entrada = valor_imovel * percentual_entrada
    valor_financiado = valor_imovel - valor_entrada
    amortizacao_mensal = valor_financiado / meses
    valor_primeira_parcela = valor_financiado * (taxa_juros / 12) + amortizacao_mensal
    valor_renda = valor_primeira_parcela / percentual_renda
    valor_ultima_parcela = (valor_financiado - amortizacao_mensal * (meses - 1)) * (taxa_juros / 12) + amortizacao_mensal
    valor_total_pago = (valor_primeira_parcela + valor_ultima_parcela) / 2 * meses
    valor_total_juros = valor_total_pago - valor_financiado

    # Retorna os resultados
    {
      valor_imovel: number_to_currency(valor_imovel, unit: 'R$ ', separator: ',', delimiter: '.'),
      valor_entrada: number_to_currency(valor_entrada, unit: 'R$ ', separator: ',', delimiter: '.'),
      valor_financiado: number_to_currency(valor_financiado, unit: 'R$ ', separator: ',', delimiter: '.'),
      valor_primeira_parcela: number_to_currency(valor_primeira_parcela, unit: 'R$ ', separator: ',', delimiter: '.'),
      valor_ultima_parcela: number_to_currency(valor_ultima_parcela, unit: 'R$ ', separator: ',', delimiter: '.'),
      valor_total_financiamento: number_to_currency(valor_financiado, unit: 'R$ ', separator: ',',
                                                                      delimiter: '.'),
      valor_renda: number_to_currency(valor_renda, unit: 'R$ ', separator: ',', delimiter: '.'),
      valor_total_juros: number_to_currency(valor_total_juros, unit: 'R$ ', separator: ',', delimiter: '.'),
      valor_total_pago: number_to_currency((valor_total_pago + valor_entrada), unit: 'R$ ', separator: ',',
                                                                               delimiter: '.')
    }
  end

  private

  def get_distance(latitude, longitude)
    walking = @gmaps.directions([@property_cordinates[0], @property_cordinates[1]], [latitude, longitude],
                                mode: 'walking', alternatives: false, units: 'metric')

    car = @gmaps.directions([@property_cordinates[0], @property_cordinates[1]], [latitude, longitude], mode: 'driving',
                                                                                                       alternatives: false, units: 'metric')

    walking_value = walking[0][:legs][0][:duration][:value]
    car_value = car[0][:legs][0][:duration][:value]

    car_text = seconds_to_time_format(car_value)
    walking_text = seconds_to_time_format(walking_value)

    { walking: walking_text, car: car_text }
  end

  def seconds_to_time_format(seconds)
    # Calculate the number of hours and minutes
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    # Build the formatted time string
    formatted_time = ''
    formatted_time += "#{hours}h " if hours.positive?
    formatted_time += "#{minutes}m"

    formatted_time
  end

  def get_data(place)
    result = { name: place[:name] }
    google_data = get_google_data(place)
    result[:total_count] = google_data.count
    items = []
    google_data.take(place[:count]).each do |item|
      items << populate_item(item)
    end
    result[:items] = items
    top = items.max_by { |x| x[:total_rating] }
    result[:top] = top
    result[:closest] = items.first
    result
  end

  def get_google_data(place)
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: place[:keyword],
                                                                            types: place[:type], rankby: 'distance',
                                                                            language: 'pt-BR')

    items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > MIN_RATING }
  end

  def populate_item(item)
    distance = get_distance(item.lat, item.lng)
    {
      name: item.name,
      rating: item.rating,
      total_rating: item.json_result_object['user_ratings_total'],
      by_foot: distance[:walking],
      by_car: distance[:car]
    }
  end
end
