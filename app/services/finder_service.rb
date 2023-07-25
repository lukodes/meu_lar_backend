class FinderService < ApplicationService
  def initialize(property, work)
    @client = GooglePlaces::Client.new(Settings.google_places_api_key)
    @gmaps = GoogleMapsService::Client.new
    @property_cordinates = Geocoder.search("postal_code: #{property[:zip_code]} | number: #{property[:address_number]}").first.coordinates
    @work_cordinates = Geocoder.search("postal_code: #{work[:zip_code]} | number: #{work[:address_number]}").first.coordinates
    @property = property
    @work = work
  end

  def transporte
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

  def drogaria
    result_items = []
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'farmácia', types: 'pharmacy',
                                                                            rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(12).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating,
                        total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def shopping
    result_items = []
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'shopping',
                                                                            types: 'shopping_mall', rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(7).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating,
                        total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def restaurante
    result_items = []
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'restaurante',
                                                                            types: 'restaurant', rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(7).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating,
                        total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def veterinario
    result_items = []
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'veterinario',
                                                                            types: 'veterinary_care', rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(7).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating,
                        total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def posto
    result_items = []
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'posto de gasolina',
                                                                            types: 'gas_station', rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(7).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating,
                        total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def academia
    result_items = []
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'academia', types: 'gym',
                                                                            rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(7).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating,
                        total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def mercado
    result_items = []
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'mercado', types: 'supermarket',
                                                                            rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(11).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating,
                        total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def hospital
    result_items = []
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'hospital', types: 'hospital',
                                                                            rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(7).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating,
                        total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def ensino
    result_items = []
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'berçario', types: 'school',
                                                                            rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(7).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating,
                        total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def ensino2
    result_items = { fundamental: [], medio: [], superior: [] }
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'ensino fundamental',
                                                                            types: 'school', rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(5).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items[:fundamental] << { name: item.name, rating: item.rating,
                                      total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end

    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'ensino médio', types: 'school',
                                                                            rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(5).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items[:medio] << { name: item.name, rating: item.rating,
                                total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end

    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: 'faculdade', types: 'university',
                                                                            rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object['user_ratings_total'] || 0) > 5 }
    items.take(5).each_with_index do |item, _index|
      distance = get_distance(item.lat, item.lng)
      result_items[:superior] << { name: item.name, rating: item.rating,
                                   total_rating: item.json_result_object['user_ratings_total'], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  private

  def get_distance(latitude, longitude)
    walking = @gmaps.directions([@property_cordinates[0], @property_cordinates[1]], [latitude, longitude],
                                mode: 'walking', alternatives: false, units: 'metric')
    car = @gmaps.directions([@property_cordinates[0], @property_cordinates[1]], [latitude, longitude], mode: 'driving',
                                                                                                       alternatives: false, units: 'metric')
    { walking: walking[0][:legs][0][:duration][:text], car: car[0][:legs][0][:duration][:text] }
  end

  def spots_grouped_by_type(property_cordinates)
    radius_in_km = 1000 * 10

    spots = {}
    @types.each do |type|
      spots[type] =
        @client.spots(property_cordinates[0], property_cordinates[1], types: type, rankby: 'prominence', radius: radius_in_km,
                                                                      language: 'pt-BR').take(5)
    end

    spots
  end

  def add_distance(property_cordinates, spots)
    @types.each do |type|
      spots[type].each do |spot|
        distance = Geocoder::Calculations.distance_between([property_cordinates[0], property_cordinates[1]],
                                                           [spot.lat, spot.lng]).round(2)

        walking = @gmaps.directions([property_cordinates[0], property_cordinates[1]], [spot.lat, spot.lng],
                                    mode: 'walking', alternatives: false, units: 'metric')
        car = @gmaps.directions([property_cordinates[0], property_cordinates[1]], [spot.lat, spot.lng],
                                mode: 'driving', alternatives: false, units: 'metric')

        spot.json_result_object['distance'] = distance
        spot.json_result_object['walking_time'] = walking[0][:legs][0][:duration][:text]
        spot.json_result_object['car_time'] = car[0][:legs][0][:duration][:text]
      end
    end

    spots
  end
end
