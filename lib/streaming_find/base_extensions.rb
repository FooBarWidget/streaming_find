ActiveRecord::Base.metaclass.class_eval do
  def find(*args, &block)
    options = args.extract_options!
    validate_find_options(options)
    set_readonly_option!(options)
    
    case args.first
      when :first then find_initial(options)
      when :last  then find_last(options)
      when :all   then find_every(options, &block)
      else             find_from_ids(args, options)
    end
  end
  
  def find_by_sql(sql)
    if block_given?
      connection.select_all(sanitize_sql(sql), "#{name} Load") do |row|
        yield instantiate(row)
      end
      nil
    else
      connection.select_all(sanitize_sql(sql), "#{name} Load").collect! do |row|
        instantiate(row)
      end
    end
  end
  
  private
    def find_every(options)
      include_associations = merge_includes(scope(:find, :include), options[:include])
      has_include_associations = include_associations.any?
      
      if block_given?
        readonly = options[:readonly]
        if has_include_associations && references_eager_loaded_tables?(options)
          find_with_associations(options) do |record|
            record.readonly! if readonly
            yield record
          end
        else
          find_by_sql(construct_finder_sql(options)) do |record|
            record.readonly! if readonly
            if has_include_associations
              preload_associations(record, include_associations)
            end
            yield record
          end
        end
        nil
      else
        if include_associations.any? && references_eager_loaded_tables?(options)
          records = find_with_associations(options)
        else
          records = find_by_sql(construct_finder_sql(options))
          if include_associations.any?
            preload_associations(records, include_associations)
          end
        end
        
        records.each { |record| record.readonly! } if options[:readonly]
        
        records
      end
    end
    
    def find_with_associations(options = {})
      if block_given?
        catch :invalid_query do
          join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(self, merge_includes(scope(:find, :include), options[:include]), options[:joins])
          select_all_rows(options.merge(:distinct => true, :group => join_dependency.join_base.aliased_primary_key), join_dependency) do |row|
            yield join_dependency.instantiate_one(row)
          end
        end
        nil
      else
        catch :invalid_query do
          join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(self, merge_includes(scope(:find, :include), options[:include]), options[:joins])
          rows = select_all_rows(options, join_dependency)
          return join_dependency.instantiate(rows)
        end
        []
      end
    end
    
    def select_all_rows(options, join_dependency, &block)
      # adds support for block
      connection.select_all(
        construct_finder_sql_with_included_associations(options, join_dependency),
        "#{name} Load Including Associations",
        &block
      )
    end
    
    def construct_finder_sql_with_included_associations(options, join_dependency)
      # adds support for :distinct
      scope = scope(:find)
      distinct = options[:distinct] ? "DISTINCT " : nil
      sql = "SELECT #{distinct}#{column_aliases(join_dependency)} FROM #{(scope && scope[:from]) || options[:from] || quoted_table_name} "
      sql << join_dependency.join_associations.collect{|join| join.association_join }.join

      add_joins!(sql, options[:joins], scope)
      add_conditions!(sql, options[:conditions], scope)
      add_limited_ids_condition!(sql, options, join_dependency) if !using_limitable_reflections?(join_dependency.reflections) && ((scope && scope[:limit]) || options[:limit])

      add_group!(sql, options[:group], options[:having], scope)
      add_order!(sql, options[:order], scope)
      add_limit!(sql, options, scope) if using_limitable_reflections?(join_dependency.reflections)
      add_lock!(sql, options, scope)

      return sanitize_sql(sql)
    end
end