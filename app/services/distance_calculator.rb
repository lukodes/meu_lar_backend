class DistanceCalculator
  def self.calculate(origin, destination)
    gmaps = GoogleMapsService::Client.new

    walking = gmaps.directions(origin, destination, mode: 'walking', units: 'metric')
    driving = gmaps.directions(origin, destination, mode: 'driving', units: 'metric')

    {
      walking: format_duration(walking[0][:legs][0][:duration][:value]),
      car: format_duration(driving[0][:legs][0][:duration][:value])
    }
  end

  def self.format_duration(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    "#{hours}h #{minutes}m".strip
  end
end