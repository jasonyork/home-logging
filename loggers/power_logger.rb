require 'mios'

class PowerLogger
  include MessageLogging

  def initialize(datasource, options)
    @datasource = datasource
    @mios = MiOS::Interface.new(options[:mios_url])
    @min_interval = options[:min_interval]
    logger.info("[PowerLogger] initialized")
  end

  def log
    logger.debug("[PowerLogger] triggered")
    return unless min_interval_passed?
    @mios.refresh!

    meter = @mios.devices.detect { |d| d.name == "Home Energy Monitor" && d.attributes['id_parent'] == 1 }
    legs = @mios.devices.select { |d| d.name == "Home Energy Monitor" && d.attributes['id_parent'] == meter.attributes['id'].to_i }
    legs.sort! { |a,b| a.id <=> b.id }

    reading_date = meter.last_reading_at
    current_data = { "Date" => reading_date.strftime("%Y-%m-%d %H:%M:%S")}
    { "Meter" => meter, "Leg 1" => legs[0], "Leg 2" => legs[1] }.each do |prefix, device|
      current_data.merge!(data_for_device(device, prefix))
    end

    unless last_result_matches_current?(current_data)
      @datasource.append_result(current_data)
      @last_data = current_data
      logger.debug("[PowerLogger] recorded: #{current_data}")
    end
  end

  def last_data
    @last_data ||= @datasource.last_result
  end

  def last_result_matches_current?(current_data)
    current_data["Date"] == @last_data["Date"]
  end

  def min_interval_passed?
    (Time.now - last_data['Date']) > @min_interval rescue true
  end

  def data_for_device(device, prefix)
    [:watts, :kWh].each_with_object({}) do |attribute, data|
       data["#{prefix} #{attribute.to_s}"] = device.send(attribute)
    end
  end

end
