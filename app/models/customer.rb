class Customer < ApplicationRecord
  has_many :support_articles, dependent: :destroy
  
  validates :name, presence: true
  validates :connection_string, presence: true
  validate :validate_sqlite_connection_string
  
  before_validation :normalize_connection_string
  
  private
  
  def normalize_connection_string
    return if connection_string.blank?
    
    # If it's just a path without sqlite3: prefix, add it
    unless connection_string.include?(':')
      self.connection_string = "sqlite3:#{connection_string}"
    end
  end
  
  def validate_sqlite_connection_string
    return if connection_string.blank?
    
    # Check if it starts with sqlite3:
    unless connection_string.start_with?('sqlite3:')
      errors.add(:connection_string, 'must be a valid database path')
      return
    end
    
    # Extract the file path
    db_path = connection_string.sub('sqlite3:', '')
    
    # Convert to absolute path relative to Rails root
    full_path = Rails.root.join(db_path).to_s
    
    # Check if the file exists
    unless File.exist?(full_path)
      errors.add(:connection_string, 'database file does not exist')
      return
    end
    
    # Check if it's a valid SQLite database
    begin
      SQLite3::Database.new(full_path) { |db| db.execute('SELECT 1') }
    rescue SQLite3::Exception => e
      errors.add(:connection_string, "is not a valid SQLite database: #{e.message}")
    end
  end
end
