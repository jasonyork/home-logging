require 'weather-api'
require 'logging'

class OutdoorTemperatureLogger
  include MessageLogging

  def initialize(datasource, options)
    @datasource = datasource
    @city_id = options[:city_id]
    @min_interval = options[:min_interval]
    logger.info("[OutdoorTemperatureLogger] initialized")
  end

  def log
    logger.debug("[OutdoorTemperatureLogger] triggered")
    return unless min_interval_passed?
    response = Weather.lookup(@city_id, Weather::Units::FAHRENHEIT)

    if last_data['Date'] != response.condition.date
      data = { "Temperature" => response.condition.temp,
               "Date" => response.condition.date.strftime("%Y-%m-%d %H:%M:%S") }
      @datasource.append_result(data)
      @last_data = data
      logger.debug("[OutdoorTemperatureLogger] recorded: #{data}")
    end
  end

  def last_data
    @last_data ||= @datasource.last_result
  end

  def min_interval_passed?
    (Time.now - last_data['Date']) > @min_interval rescue true
  end

end
