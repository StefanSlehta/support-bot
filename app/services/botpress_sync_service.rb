class BotpressSyncService
  RESERVED_COLUMNS = %w[id createdAt updatedAt computed created_at updated_at].freeze
  TABLE_NAME_MAX_LENGTH = 30

  def initialize(customer)
    @customer = customer
    @schema_types = {}
    @existing_tables = nil
  end

  def sync_database
    @existing_tables = fetch_existing_botpress_tables
    schema = fetch_database_schema
    create_botpress_tables(schema)
    populate_botpress_tables(schema)
  ensure
    remove_customer_db_connection
  end

  private

  def fetch_existing_botpress_tables
    response = botpress_api_request(:get, "#{botpress_base_url}/v1/tables")
    
    unless response.success?
      raise "Failed to fetch existing tables: #{response.body}"
    end

    JSON.parse(response.body)['tables'].map { |table| table['name'] }
  end

  def table_exists?(table_name)
    @existing_tables.include?(table_name)
  end

  def delete_table(table_name)
    response = botpress_api_request(
      :delete,
      "#{botpress_base_url}/v1/tables/#{table_name}"
    )

    unless response.success?
      raise "Failed to delete table #{table_name}: #{response.body}"
    end
  end

  def establish_customer_db_connection
    if @customer.connection_string.start_with?('sqlite3:')
      db_path = @customer.connection_string.sub('sqlite3:', '')
      config = {
        adapter: 'sqlite3',
        database: db_path
      }
    else
      raise "Unsupported database type in connection string: #{@customer.connection_string}"
    end
    
    ActiveRecord::Base.establish_connection(config)
  end

  def fetch_database_schema
    establish_customer_db_connection
    connection = ActiveRecord::Base.connection
    tables = connection.tables - %w[schema_migrations ar_internal_metadata]
    
    result = {}
    tables.each do |table_name|
      columns = connection.columns(table_name)
      
      @schema_types[table_name] = {}
      columns.each do |col|
        @schema_types[table_name][col.name.to_s] = active_record_type_to_botpress_type(col.type)
      end
      
      result[table_name] = build_table_schema(columns)
    end
    
    result
  end

  def build_table_schema(columns)
    filtered_columns = columns.reject { |col| RESERVED_COLUMNS.include?(col.name) }
    
    {
      required_fields: filtered_columns.reject(&:null).map(&:name),
      fields: build_fields_schema(filtered_columns)
    }
  end

  def build_fields_schema(columns)
    columns.each_with_object({}) do |col, fields|
      field_name = sanitize_field_name(col.name)
      fields[field_name] = {
        type: active_record_type_to_botpress_type(col.type),
        nullable: col.null
      }
    end
  end

  def sanitize_field_name(name)
    RESERVED_COLUMNS.include?(name.to_s) ? "#{name}_value" : name.to_s
  end

  def create_botpress_tables(schema)
    schema.each do |table_name, table_schema|
      botpress_table_name = sanitize_table_name(table_name)
      
      if table_exists?(botpress_table_name)
        delete_table(botpress_table_name)
      end

      botpress_schema = convert_to_botpress_schema(botpress_table_name, table_schema)
      create_botpress_table(table_name, botpress_schema)
    end
  end

  def create_botpress_table(table_name, schema)
    response = botpress_api_request(
      :post,
      "#{botpress_base_url}/v1/tables",
      body: schema
    )

    raise "Failed to create table #{table_name}: #{response.body}" unless response.success?
  end

  def populate_botpress_tables(schema)
    schema.each do |table_name, _table_schema|
      populate_botpress_table(table_name)
    end
  end

  def populate_botpress_table(table_name)
    model = Class.new(ActiveRecord::Base) { self.table_name = table_name }
    botpress_table_name = sanitize_table_name(table_name)

    model.find_each(batch_size: 1) do |record|
      row = convert_to_botpress_row(record, table_name)
      
      data = {
        table: botpress_table_name,
        rows: [row]
      }

      response = botpress_api_request(
        :post,
        "#{botpress_base_url}/v1/tables/#{botpress_table_name}/rows",
        body: data
      )

      unless response.success?
        raise "Failed to populate row in table #{table_name}: #{response.body}"
      end
    end
  end

  def convert_to_botpress_row(record, table_name)
    attributes = record.attributes.transform_keys(&:to_s)
    result = {}
    
    attributes.each do |key, value|
      next if RESERVED_COLUMNS.include?(key)
      
      target_type = @schema_types[table_name][key]
      if target_type.nil?
        raise "No type mapping found for column '#{key}'"
      end
      
      result[key] = convert_value_to_type(value, target_type)
    end
    
    result
  end

  def convert_value_to_type(value, target_type)
    return '' if value.nil?

    case target_type
    when 'number'
      case value
      when Integer
        value
      when Float
        value
      when String
        if value.include?('.')
          value.to_f
        else
          value.to_i
        end
      when BigDecimal
        value.to_i
      else
        value.to_i
      end
    when 'boolean'
      value == true || value == 1 || value.to_s.downcase == 'true'
    when 'string'
      case value
      when Time, DateTime, Date then value.iso8601
      when BigDecimal then value.to_s('F')
      else value.to_s
      end
    else
      value.to_s
    end
  end

  def convert_to_botpress_schema(table_name, table_schema)
    {
      name: table_name,
      schema: {
        type: 'object',
        required: table_schema[:required_fields],
        properties: table_schema[:fields].transform_values do |field|
          {
            type: field[:type],
            'x-zui': {
              searchable: true,
              nullable: field[:nullable]
            }
          }
        end
      }
    }
  end

  def sanitize_table_name(name)
    sanitized = name.to_s.gsub(/[^A-Za-z0-9_]/, '_')
    sanitized = "t_#{sanitized}" if sanitized =~ /^\d/
    sanitized = sanitized.sub(/Table$/, '').sub(/_+$/, '')
    sanitized = "#{sanitized}Table"
    
    max_base_length = TABLE_NAME_MAX_LENGTH - 'Table'.length
    if sanitized.length > TABLE_NAME_MAX_LENGTH
      sanitized = "#{sanitized[0...max_base_length]}Table"
    end
    
    sanitized
  end

  def active_record_type_to_botpress_type(ar_type)
    case ar_type.to_s
    when 'integer', 'decimal', 'float' then 'number'
    when 'datetime', 'timestamp', 'time', 'date' then 'string'
    when 'boolean' then 'boolean'
    when 'binary' then 'string'
    else 'string'
    end
  end

  def botpress_api_request(method, url, body: nil)
    HTTParty.public_send(
      method,
      url,
      headers: botpress_headers,
      body: body&.to_json
    )
  end

  def botpress_headers
    {
      'Authorization' => "bearer #{botpress_token}",
      'x-bot-id' => botpress_bot_id,
      'Content-Type' => 'application/json'
    }
  end

  def botpress_token
    ENV.fetch('BOTPRESS_TOKEN') { raise 'BOTPRESS_TOKEN environment variable is not set' }
  end

  def botpress_bot_id
    ENV.fetch('BOTPRESS_BOT_ID') { raise 'BOTPRESS_BOT_ID environment variable is not set' }
  end

  def botpress_base_url
    'https://api.botpress.cloud'
  end

  def remove_customer_db_connection
    ActiveRecord::Base.connection.disconnect!
    ActiveRecord::Base.establish_connection(
      Rails.configuration.database_configuration[Rails.env]
    )
  end
end 