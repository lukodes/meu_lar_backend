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

  # def transporte
  #   date = Date.tomorrow
  #   dia_util = date.next_weekday
  #   peak_time = DateTime.new(dia_util.year, dia_util.month, dia_util.day, 11, 0, 0) # 8 horas da manhã

  #   directions = @gmaps.directions(
  #     "#{@property_cordinates[0]},#{@property_cordinates[1]}",
  #     "#{@work_cordinates[0]},#{@work_cordinates[1]}",
  #     mode: 'driving',
  #     departure_time: peak_time,
  #     language: 'pt-BR'
  #   )

  #   origin = "#{@property[:address]}, #{@property[:address_number]} - #{@property[:district]}, #{@property[:city]} - #{@property[:state]}, #{@property[:zip_code]}"
  #   destination = "#{@work[:address]}, #{@work[:address_number]} - #{@work[:district]}, #{@work[:city]} - #{@work[:state]}, #{@work[:zip_code]}"
  #   directions_public = @gmaps.directions(
  #     origin,
  #     destination,
  #     mode: 'transit',
  #     departure_time: peak_time,
  #     language: 'pt-BR'
  #   )

  #   instructions_public = []
  #   directions_public[0][:legs][0][:steps].each_with_index do |step, index|
  #     instructions_public << { index: index, instruction: step[:html_instructions], distance: step[:distance][:text] }
  #   end

  #   duration_peak = directions[0][:legs][0][:duration_in_traffic][:text]
  #   duration_nopeak = directions[0][:legs][0][:duration][:text]
  #   work_distance = directions[0][:legs][0][:distance][:text]

  #   {
  #     work_distance: work_distance,
  #     duration_peak: duration_peak,
  #     duration_nopeak: duration_nopeak,
  #     instructions_public: instructions_public
  #   }
  # end

  private

  def get_distance(latitude, longitude)
    walking = @gmaps.directions([@property_cordinates[0], @property_cordinates[1]], [latitude, longitude],
                                mode: 'walking', alternatives: false, units: 'metric')
    car = @gmaps.directions([@property_cordinates[0], @property_cordinates[1]], [latitude, longitude], mode: 'driving',
                                                                                                       alternatives: false, units: 'metric')
    { walking: walking[0][:legs][0][:duration][:text], car: car[0][:legs][0][:duration][:text] }
  end

  def get_data(place)
    result = { name: place[:name] }
    google_data = get_google_data(place)
    result[:total_count] = google_data.count
    items = []
    google_data.take(place.count).each do |item|
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
