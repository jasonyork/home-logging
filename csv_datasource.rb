require 'csv'

class CsvDatasource
  def initialize(filename)
    @filename = filename
    csv = CSV.read(@filename, headers: true, converters: [:date_time])
    @columns = csv.headers
    @last_result = csv.entries.last.to_hash
  end

  def last_result
    @last_result
  end

  def append_result(values)
    row = @columns.each_with_object([]) do |column, row|
      row << values[column].to_s
    end
    CSV.open(@filename, "ab") do |csv|
      csv << row
    end
    @last_result = values
  end
end
