class FinderService < ApplicationService
  def initialize(zip_code, types = ['school', 'hospital', 'gym', 'supermarket'])
    @client = GooglePlaces::Client.new(Settings.google_places_api_key)
    @gmaps = GoogleMapsService::Client.new
    @zip_code = zip_code
    @types = types
  end

  def call
    property_cordinates = Geocoder.search(@zip_code).first.coordinates

    spots = spots_grouped_by_type(property_cordinates)
    spots = add_distance(property_cordinates, spots)

    spots
  end

  private

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
