
require 'rubygems'
require 'bundler/setup'
require 'dotenv'
Dotenv.load
require 'active_support'
require 'rufus-scheduler'
require './message_logging'
require './loggers/outdoor_temperature_logger'
require './loggers/thermostat_logger'
require './loggers/power_logger'
require './fusion_table_datasource'
require './csv_datasource'
require 'pry-byebug'

# DATASOURCE = FusionTableDatasource
DATASOURCE = CsvDatasource

home_loggers = [
  { class: OutdoorTemperatureLogger, table: ENV['OUTDOOR_TEMPERATURE_TABLE'], interval: '1h',
    options: { city_id: 12773864, min_interval: 3555 } },
  { class: ThermostatLogger, table: ENV['THERMOSTAT_TABLE'], interval: '1m',
    options: { mios_url: ENV['VERA_URL'], min_interval: 55 } },
  { class: PowerLogger, table: ENV['POWER_TABLE'], interval: '5m',
    options: { mios_url: ENV['VERA_URL'], min_interval: 555 } }
]

scheduler = Rufus::Scheduler.new
home_loggers.each do |home_logger|
  logger_instance = home_logger[:class].new(DATASOURCE.new(home_logger[:table]), home_logger[:options])
  scheduler.every home_logger[:interval], logger_instance: logger_instance, first_in: '5s' do |job|
    job.opts[:logger_instance].log
  end
end

scheduler.join
