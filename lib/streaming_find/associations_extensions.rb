ActiveRecord::Associations::ClassMethods::JoinDependency.class_eval do
  def instantiate_one(row)
    join_base.instantiate(row, false)
  end
end

ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase.class_eval do
  def instantiate(row, cache = true)
    if cache
      @cached_record[record_id(row)] ||= active_record.send(:instantiate, extract_record(row))
    else
      active_record.send(:instantiate, extract_record(row))
    end
  end
end