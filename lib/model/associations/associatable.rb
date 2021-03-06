require_relative 'has_many_options'
require_relative 'belongs_to_options'

module Associatable

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    self.define_method(name) do
      validations = self.class.validators
        .map { |validator| [validator.attribute, validator.options[:presence]] }

      unless options.optional || validations.include?([options.foreign_key, true])
        self.class.validates options.foreign_key, presence: true 
      end
      
      options.model_class.find(self.send(options.foreign_key))
    end
  end

  def has_many(name, options = {})
    if options[:through] && options[:source]
      has_many_through(name, options[:through], options[:source])
    else
      options = HasManyOptions.new(name, self.name, options)
      assoc_options[name] = options
    
      self.define_method(name) do 
        options.model_class.where(options.foreign_key => self.send(options.primary_key)).parsed_query
      end
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end

  def has_one(name, options)
    through_name = options[:through]
    source_name = options[:source]

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      through_pk = through_options.primary_key
      through_fk = through_options.foreign_key

      source_table = source_options.table_name
      source_pk = source_options.primary_key
      source_fk = source_options.foreign_key

      key_val = self.send(through_fk)
      results = DBConnection.execute(<<-SQL, key_val)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{source_fk} = #{source_table}.#{source_pk}
        WHERE
          #{through_table}.#{through_pk} = $1
      SQL

      source_options.model_class.parse_all(results).first
    end
  end

  def has_many_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      if through_options.is_a?(BelongsToOptions)
        through_self_id = through_options.primary_key
        self_through_id = through_options.foreign_key
      else
        through_self_id = through_options.foreign_key
        self_through_id = through_options.primary_key
      end

      if source_options.is_a?(BelongsToOptions)
        through_source_id = source_options.foreign_key
        source_through_id = source_options.primary_key
      else
        through_source_id = source_options.primary_key
        source_through_id = source_options.foreign_key
      end

      through_table = through_options.table_name
      source_table = source_options.table_name

      key_val = self.send(:id)
      results = DBConnection.execute(<<-SQL, key_val)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{through_source_id} = #{source_table}.#{source_through_id}
        JOIN
          #{self.class.table_name}
        ON
          #{self.class.table_name}.#{self_through_id} = #{through_table}.#{through_self_id}
        WHERE
          #{self.class.table_name}.id = $1
      SQL

      source_options.model_class.parse_all(results)
    end
  end

end