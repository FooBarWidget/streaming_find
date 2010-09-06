ROOT = File.expand_path(File.dirname(__FILE__) + "/..")
$LOAD_PATH.unshift("#{ROOT}/lib")

##### Initialize libraries #####

require 'rubygems'
require 'yaml'
require 'logger'
require 'test/unit'

config = YAML.load_file("#{ROOT}/test/database.yml")
if config['rails']
  if config['rails']['version']
    gem 'rails', "=#{config['rails']['version']}"
  elsif config['rails']['vendor']
    vendor_path = config['rails']['vendor']
    $LOAD_PATH.unshift("#{vendor_path}/activesupport/lib")
    $LOAD_PATH.unshift("#{vendor_path}/activerecord/lib")
  end
end
require 'active_record'
require 'active_record/test_case'


config_name = ENV['CONFIG'] || "mysql"
abort "No configuration named '#{config_name}' in test/database.yml" if !config[config_name]

logger = Logger.new(STDERR)
logger.level = Logger::INFO
ActiveRecord::Base.logger = logger
ActiveRecord::Base.establish_connection(config[config_name])
ActiveRecord::Base.connection  # force loading database driver

if config[config_name]['dummy']
  ENV['STREAMING_FIND_USE_DUMMY_ADAPTER_EXTENSION'] = "1"
end
require 'streaming_find'


##### Create test tables, test models and test data #####

TOTAL_NUMBERS = 100

connection = ActiveRecord::Base.connection
connection.create_table :numbers, :force => true do |t|
  t.integer :value, :null => false
end
connection.create_table :authors, :force => true do |t|
  t.string :name, :null => false
  t.integer :number_id, :null => false
end
connection.create_table :books, :force => true do |t|
  t.string :name, :null => false
  t.integer :author_id, :null => false
  t.integer :tag, :null => false
end

class Number < ActiveRecord::Base
  has_many :authors
end

class Author < ActiveRecord::Base
  has_many :books, :order => 'name'
  belongs_to :number
end

class Book < ActiveRecord::Base
  belongs_to :author
end

def repopulate_tables
  ActiveRecord::Base.transaction do
    Number.delete_all
    TOTAL_NUMBERS.times do |i|
      Number.create!(:value => i)
    end
    zero = Number.find_by_value(0)
    one = Number.find_by_value(1)
    
    Author.delete_all
    
    ken = zero.authors.create!(:name => 'Ken Akamatsu')
    ken.books.create!(:name => 'Love Hina', :tag => 0)
    ken.books.create!(:name => 'Negima', :tag => 1)
    
    masashi = one.authors.create!(:name => 'Masashi Kishimoto')
    masashi.books.create!(:name => 'Naruto', :tag => 0)
    
    rumiko = one.authors.create!(:name => 'Rumiko Takahashi')
    rumiko.books.create!(:name => 'Inu Yasha', :tag => 0)
    rumiko.books.create!(:name => 'Ranma 1/2', :tag => 0)
    rumiko.books.create!(:name => 'Urusei Yatsura', :tag => 1)
    
    tsugumi = one.authors.create!(:name => 'Tsugumi Ohba')
    tsugumi.books.create(:name => 'Death Note', :tag => 2)
  end
end

def debug_queries
  ActiveRecord::Base.logger.level = Logger::DEBUG
  yield
ensure
  ActiveRecord::Base.logger.level = Logger::INFO
end