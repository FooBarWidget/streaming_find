ActiveRecord::ConnectionAdapters::SQLiteAdapter.class_eval do
  def select_all(sql, name = nil)
    if block_given?
      catch_schema_changes do
        log(sql, name) do
          @connection.execute(sql) do |row|
            record = {}
            row.each_key do |key|
              if key.is_a?(String)
                record[key.sub(/^"?\w+"?\./, '')] = row[key]
              end
            end
            yield record
          end
        end
      end
    else
      select(sql, name)
    end
  end
end