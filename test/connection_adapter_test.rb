require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class ConnectionAdapterTest < ActiveSupport::TestCase
  def setup
    repopulate_tables
    @connection = Number.connection
  end
  
  def test_select_all_with_block
    found_numbers = []
    @connection.select_all("SELECT * FROM numbers") do |row|
      found_numbers << row["value"]
    end
    assert_equal TOTAL_NUMBERS, found_numbers.size
    TOTAL_NUMBERS.times do |number|
      assert found_numbers.include?(number.to_s)
    end
  end
  
  def test_select_all_without_block
    found_numbers = []
    @connection.select_all("SELECT * FROM numbers").each do |row|
      found_numbers << row["value"]
    end
    assert_equal TOTAL_NUMBERS, found_numbers.size
    TOTAL_NUMBERS.times do |number|
      assert found_numbers.include?(number.to_s)
    end
  end
end