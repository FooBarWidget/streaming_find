ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
  target = defined?(Mysql::Result) ? Mysql::Result : MysqlRes
  
  # Ruby driver has a version string and returns null values in each_hash
  # C driver >= 2.7 returns null values in each_hash
  if Mysql.const_defined?(:VERSION) && (Mysql::VERSION.is_a?(String) || Mysql::VERSION >= 20700)
    target.class_eval do
      alias_method :each_hash_with_nulls, :each_hash
    end
    
  # adapters before 2.7 don't have a version constant
  # and don't return null values in each_hash
  else
    target.class_eval do
      def each_hash_with_nulls
        all_fields = fetch_fields.inject({}) do |fields, f|
          fields[f.name] = nil; fields
        end
        each_hash do |row|
          yield all_fields.dup.update(row)
        end
      end
    end
  end
	
  def select_all(sql, name = nil)
    if block_given?
      @connection.query_with_result = true
      count = 0
      result = execute(sql, name)
      begin
        result.each_hash_with_nulls do |row|
          yield row
          count += 1
        end
        count
      ensure
        result.free
      end
    else
      @connection.query_with_result = true
      result = execute(sql, name)
      begin
        result.all_hashes
      ensure
        result.free
      end
    end
  end
end