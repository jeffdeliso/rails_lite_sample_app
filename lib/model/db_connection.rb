require 'pg'

PRINT_QUERIES = ENV['PRINT_QUERIES'] == 'true'
ROOT_FOLDER = File.join(File.dirname(__FILE__), '..', '..')
SQL_FILE = File.join(ROOT_FOLDER, 'db', 'database.sql')
# DB_FILE = gFile.join(ROOT_FOLDER, 'db', 'database.db')
# DB_FILE = ENV['DATABASE_URL']
DB_FILE = ENV['DATABASE_URL']

class DBConnection
  def self.open(db_file_name)
    @db ||= PG::Connection.new(db_file_name)
    # @db.results_as_hash = false
    # @db.type_translation = true

    @db
  end

  def self.reset
    commands = [
      "dropdb '#{DB_FILE}'",
      "createdb '#{DB_FILE}'",
      "psql '#{DB_FILE}' < '#{SQL_FILE}'"
    ]
    # commands = [
    #   "rm '#{DB_FILE}'",
    #   "cat '#{SQL_FILE}' | sqlite3 '#{DB_FILE}'"
    # ]

    commands.each { |command| `#{command}` }
    DBConnection.open(DB_FILE)
  end

  def self.instance
    # reset if @db.nil?
    @db ||= DBConnection.open(DB_FILE)

    @db
  end

  def self.execute(*args)
    print_query(*args)
    instance.exec(*args)
  end

  def self.execute2(*args)
    print_query(*args)
    instance.exec(*args)
  end

  def self.last_insert_row_id
    instance.last_insert_row_id
  end

  private

  def self.print_query(query, *interpolation_args)
    # return unless PRINT_QUERIES

    puts '--------------------'
    puts query
    unless interpolation_args.empty?
      puts "interpolate: #{interpolation_args.inspect}"
    end
    puts '--------------------'
  end
end
