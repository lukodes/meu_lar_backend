class FinderService < ApplicationService
  def initialize(zip_code)
    @client = GooglePlaces::Client.new(Settings.google_places_api_key)
    @gmaps = GoogleMapsService::Client.new
    @zip_code = zip_code
    @property_cordinates = Geocoder.search(@zip_code).first.coordinates
  end

  def ensino
    result_items = []
    bercarios = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: "berçario", types: 'school', rankby: 'distance', language: 'pt-BR')
    bercarios = bercarios.select { |item| (item.json_result_object["user_ratings_total"] || 0) > 5 }
    bercarios.take(7).each_with_index do |item, index|
      distance = get_distance(item.lat, item.lng)
      result_items << { name: item.name, rating: item.rating, total_rating: item.json_result_object["user_ratings_total"], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end

  def ensino2
    result_items = { fundamental: [], medio: [], superior: []}
    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: "ensino fundamental", types: 'school', rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object["user_ratings_total"] || 0) > 5 }
    items.take(5).each_with_index do |item, index|
      distance = get_distance(item.lat, item.lng)
      result_items[:fundamental] << { name: item.name, rating: item.rating, total_rating: item.json_result_object["user_ratings_total"], walking_time: distance[:walking], car_time: distance[:car] }
    end

    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: "ensino médio", types: 'school', rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object["user_ratings_total"] || 0) > 5 }
    items.take(5).each_with_index do |item, index|
      distance = get_distance(item.lat, item.lng)
      result_items[:medio] << { name: item.name, rating: item.rating, total_rating: item.json_result_object["user_ratings_total"], walking_time: distance[:walking], car_time: distance[:car] }
    end

    items = @client.spots(@property_cordinates[0], @property_cordinates[1], keyword: "ensino superior", types: 'school', rankby: 'distance', language: 'pt-BR')
    items = items.select { |item| (item.json_result_object["user_ratings_total"] || 0) > 5 }
    items.take(5).each_with_index do |item, index|
      distance = get_distance(item.lat, item.lng)
      result_items[:superior] << { name: item.name, rating: item.rating, total_rating: item.json_result_object["user_ratings_total"], walking_time: distance[:walking], car_time: distance[:car] }
    end
    result_items
  end


  private

  def get_distance(latitude, longitude)
    walking = @gmaps.directions([@property_cordinates[0], @property_cordinates[1]], [latitude, longitude], mode: 'walking', alternatives: false, units: 'metric')
    car = @gmaps.directions([@property_cordinates[0], @property_cordinates[1]], [latitude, longitude], mode: 'driving', alternatives: false, units: 'metric')
    { walking: walking[0][:legs][0][:duration][:text], car: car[0][:legs][0][:duration][:text] }
  end

  def spots_grouped_by_type(property_cordinates)
    radius_in_km = 1000 * 10

    spots = {}
    @types.each do |type|
      spots[type] = @client.spots(property_cordinates[0], property_cordinates[1], types: type, rankby: 'prominence', radius: radius_in_km, language: 'pt-BR').take(5)
    end

    spots
  end

  def add_distance(property_cordinates, spots)
    @types.each do |type|
      spots[type].each do |spot|
        distance = Geocoder::Calculations.distance_between([property_cordinates[0], property_cordinates[1]], [spot.lat, spot.lng]).round(2)

        walking = @gmaps.directions([property_cordinates[0], property_cordinates[1]], [spot.lat, spot.lng], mode: 'walking', alternatives: false,  units: 'metric')
        car = @gmaps.directions([property_cordinates[0], property_cordinates[1]], [spot.lat, spot.lng], mode: 'driving', alternatives: false, units: 'metric')

        spot.json_result_object["distance"] = distance
        spot.json_result_object["walking_time"] = walking[0][:legs][0][:duration][:text]
        spot.json_result_object["car_time"] = car[0][:legs][0][:duration][:text]
      end
    end

    spots
  end
end
