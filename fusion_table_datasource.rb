require 'googleauth'
require 'google/apis/fusiontables_v2'

class FusionTableDatasource

  # https://github.com/google/google-api-ruby-client/issues/253
  cert_path = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
  ENV['SSL_CERT_FILE'] = cert_path

  @@service = Google::Apis::FusiontablesV2::FusiontablesService.new

  scopes =  ['https://www.googleapis.com/auth/fusiontables']
  @@service.authorization = Google::Auth.get_application_default(scopes)

  def initialize(table)
    @table = table
    @columns = @@service.list_columns(@table).items.map(&:name)
  end

  def last_result
    values = @@service.sql_query("SELECT * FROM #{@table} ORDER BY Date DESC LIMIT 1").rows.first
    last_result = Hash[@columns.zip values]
    last_result['Date'] = Time.parse(last_result['Date']) if last_result['Date']
    last_result
  end

  def append_result(values)
    @@service.sql_query("INSERT INTO #{@table} ('#{values.keys.join("','")}')
                         VALUES ('#{values.values.join("', '")}')")
  end
end
