require 'active_support/inflector'
require_relative './db_connection'
require_relative './relations/searchable'
require_relative './associations/associatable'
require_relative './validations/validations'
require_relative './relations/relation'
require_relative './model_callbacks'

class ModelBase
  extend Searchable
  extend Associatable
  include Validations
  include ModelCallbacks
  
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      Select 
        * 
      FROM 
        #{self.table_name}
      LIMIT 0
    SQL
    .fields.map!(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do 
        attributes[column]
      end
      
      setter_name = column.to_s + "="
      define_method(setter_name) do |val|
        attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.underscore.pluralize
  end

  def self.all
    results = DBConnection.execute("Select * FROM #{self.table_name}")
    parse_all(results)
  end

  def self.first
    results = DBConnection.execute("Select * FROM #{self.table_name} LIMIT 1")
    parse_all(results).first
  end

  def self.last
    all.last
  end

  def self.parse_all(results)
    instances = []

    results.each do |result|
      instances << self.new(result)
    end

    instances
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, [id])
      Select 
        * 
      FROM 
        #{table_name}
      WHERE 
        id = $#{1}
    SQL

    parse_all(results).first
  end

  def initialize(params = {})
    self.class.finalize!

    params.each do |attribute, val|
      setter = attribute.to_s + "="
      raise "Unknown attribute '#{k}'" unless self.class.method_defined?(setter.to_sym)
      self.send(setter, val)
    end
  end

  def update(params = {})
    params.each do |attribute, val|
      setter = attribute.to_s + "="
      raise "Unknown attribute '#{k}'" unless self.class.method_defined?(setter.to_sym)
      self.send(setter, val)
    end

    self
  end

  def update_attributes(params = {})
    update(params)
    save ? true : false
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def save
    if self.valid?
      id ? update_database : insert
      true
    else
      false
    end
  end

  def save!
    if self.valid?
      id ? update_database : insert
      self
    else
      raise self.errors.join(", ")
    end
  end
  
  def destroy
    DBConnection.execute(<<-SQL, [id])
      DELETE
      FROM
        #{self.class.table_name}
      WHERE
        id = $#{1}
    SQL
  end

  private
  
  def insert
    raise "#{self} already in database" if self.id
    id = DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{column_names})
      VALUES
        (#{question_marks})
      RETURNING
        id
    SQL
    
    self.id = id.first['id']
  end
  
  def update_database
    arr = attribute_values
    arr << id
    DBConnection.execute(<<-SQL, arr)
      UPDATE
        #{self.class.table_name}
      SET
        #{update_string}
      WHERE
        id = $#{arr.length}
    SQL
  end
  
  def question_marks
    attributes.map.with_index { |_, idx| "$#{idx + 1}"}.join(", ")
  end
  
  def column_names 
    attributes.keys.map(&:to_s).join(", ")
  end
  
  def update_string
    attributes.keys.map.with_index { |attr, idx| "#{attr} = $#{idx + 1}" }.join(", ")
  end
end