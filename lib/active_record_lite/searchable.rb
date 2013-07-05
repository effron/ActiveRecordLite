require_relative './db_connection'

module Searchable
  def where(params)
    where = params.keys.map{ |key| "#{key} = ?"}.join(" AND ")
    query = <<-SQL
    SELECT *
      FROM #{table_name}
     WHERE #{where}
    SQL

    results = DBConnection.execute(query, *params.values)
    self.parse_all(results)
  end
end