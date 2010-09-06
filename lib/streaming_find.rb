if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  require 'streaming_find/mysql_adapter_extensions'
else
  require 'streaming_find/dummy_adapter_extensions'
end
require 'streaming_find/base_extensions'
require 'streaming_find/associations_extensions'
require 'streaming_find/association_collection_extensions'