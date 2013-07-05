require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  def self.set_table_name(table_name)
    @table_name = table_name.underscore
  end

  def self.table_name
    @table_name
  end

  def self.all
    query = <<-SQL
      SELECT *
        FROM #{table_name}
    SQL
    row_array = DBConnection.execute(query)
    row_array.map do |row|
      self.new(row)
    end
  end

  def self.find(id)
    query = <<-SQL
      SELECT *
        FROM #{table_name}
       WHERE id = ?
    SQL

    row = DBConnection.execute(query, id)[0]
    self.new(row)
  end

  def save
    id ? update : create
  end

  private

  def attribute_values
    self.instance_variables.map { |iv| instance_variable_get(iv) }
  end

  def create
    attr_names = self.instance_variables.map { |iv| iv.to_s[1..-1] }.join(", ")
    q_marks = (['?'] * self.instance_variables.length).join(", ")

    query = <<-SQL
      INSERT INTO #{self.class.table_name} (#{attr_names}) VALUES (#{q_marks})
    SQL

    DBConnection.execute(query, *attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    attr_names = self.instance_variables.map{ |iv| iv.to_s[1..-1] }
    set_string = attr_names.join(" = ?,") + "= ?"

    query = <<-SQL
    UPDATE #{self.class.table_name} SET #{set_string} WHERE id = #{id}
    SQL

    DBConnection.execute(query, *attribute_values)
  end

end
