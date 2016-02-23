require 'mios'
require 'logging'
require 'time'

class ThermostatLogger
  include MessageLogging

  def initialize(datasource, options)
    @datasource = datasource
    @mios = MiOS::Interface.new(options[:mios_url])
    @min_interval = options[:min_interval]
    logger.info("[ThermostatLogger] initialized")
  end

  def log
    logger.debug("[ThermostatLogger] triggered")
    return unless min_interval_passed?
    @mios.refresh!
    thermostat = @mios.devices.detect { |d| d.name == "Thermostat" }

    current_data = [:operating_state, :heat_target, :cool_target,
     :mode, :temperature, :fan_mode].each_with_object({}) do |attribute, data|
       data[attribute.to_s.titleize] = thermostat.send(attribute).to_s
    end.merge("Date" => Time.now.iso8601)

    unless last_result_matches_current?(current_data)
      @datasource.append_result(current_data)
      @last_data = current_data
      logger.debug("[ThermostatLogger] recorded: #{current_data}")
    end
  end

  def last_data
    @last_data ||= @datasource.last_result
  end

  def last_result_matches_current?(current_data)
    (current_data.reject { |k,v| k == "Date" }) == (last_data.reject { |k,v| k == "Date" })
  end

  def min_interval_passed?
    (Time.now - last_data['Date']) > @min_interval rescue true
  end
end
