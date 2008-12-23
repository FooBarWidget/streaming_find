ActiveRecord::Associations::AssociationCollection.class_eval do
  def find(*args, &block)
    options = args.extract_options!

    # If using a custom finder_sql, scan the entire collection.
    if @reflection.options[:finder_sql]
      expects_array = args.first.kind_of?(Array)
      ids           = args.flatten.compact.uniq.map { |arg| arg.to_i }

      if ids.size == 1
        id = ids.first
        record = load_target.detect { |r| id == r.id }
        expects_array ? [ record ] : record
      else
        load_target.select { |r| ids.include?(r.id) }
      end
    else
      conditions = "#{@finder_sql}"
      if sanitized_conditions = sanitize_sql(options[:conditions])
        conditions << " AND (#{sanitized_conditions})"
      end
      
      options[:conditions] = conditions

      if options[:order] && @reflection.options[:order]
        options[:order] = "#{options[:order]}, #{@reflection.options[:order]}"
      elsif @reflection.options[:order]
        options[:order] = @reflection.options[:order]
      end
      
      # Build options specific to association
      construct_find_options!(options)
      
      merge_options_from_reflection!(options)
      
      # Pass through args exactly as we received them.
      args << options
      @reflection.klass.find(*args, &block)
    end
  end
  
  def each(&block)
    if loaded? || (@owner.new_record? && !foreign_key_present)
      method_missing(:each, &block)
    else
      find(:all, &block)
    end
  end
end