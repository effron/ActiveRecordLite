require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_table
    other_class.table_name
  end

  def other_class
    @other_class_name.constantize
  end
end

class BelongsToAssocParams < AssocParams

  attr_reader :primary_key, :foreign_key

  def initialize(name, params)
    @other_class_name = params[:class_name] || name.to_s.camelize
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{name}_id"
    @name = name
  end

  def type
    @name.to_s.camelize.constantize
  end
end

class HasManyAssocParams < AssocParams

  attr_reader :primary_key, :foreign_key

  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] || name.to_s.singularize.camelize
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{self_class.to_s.underscore}_id"
  end

  def type
  end
end

module Associatable
  def assoc_params
    if @assoc_params
      @assoc_params
    else
      @assoc_params = {}
      @assoc_params
    end
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    assoc_params[name] = aps
    define_method(name) do
      query = <<-SQL
        SELECT *
          FROM #{aps.other_table}
         WHERE #{aps.primary_key} = ?
      SQL

      results = DBConnection.execute(query, self.send(aps.foreign_key))

      aps.other_class.parse_all(results).first
    end

  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params, self.class)

    define_method(name) do
      query = <<-SQL
        SELECT *
          FROM #{aps.other_table}
         WHERE #{aps.foreign_key} = ?
      SQL

      results = DBConnection.execute(query, self.send(aps.primary_key))

      aps.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)


    define_method(name) do
      aps1 = self.class.assoc_params[assoc1]
      aps2 = aps1.other_class.assoc_params[assoc2]
      query = <<-SQL
        SELECT #{aps2.other_table}.*
          FROM #{aps2.other_table}
          JOIN #{aps1.other_table}
            ON #{aps1.other_table}.#{aps1.primary_key}
               = #{aps2.other_table}.#{aps2.primary_key}
         WHERE #{self.send(aps1.foreign_key)}
               = #{self.human.send(aps2.foreign_key)}
      SQL

      results = DBConnection.execute(query)
      aps2.type.parse_all(results).first
    end
  end
end
