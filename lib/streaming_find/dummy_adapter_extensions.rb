ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
  def select_all_with_streaming_find(sql, name = nil)
    if block_given?
      select_all_without_streaming_find(sql, name).each do |row|
        yield(row)
      end
    else
      select_all_without_streaming_find(sql, name)
    end
  end
  
  alias_method_chain :select_all, :streaming_find
end