require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class FindersTest < ActiveSupport::TestCase
  def setup
    repopulate_tables
  end
  
  def test_base_find_all_with_block
    found_numbers = []
    Number.find(:all) do |record|
      found_numbers << record.value
    end
    assert_equal TOTAL_NUMBERS, found_numbers.size
    TOTAL_NUMBERS.times do |number|
      assert found_numbers.include?(number)
    end
  end
  
  def test_base_find_all_with_block_and_readonly_flag
    found_numbers = []
    Number.find(:all, :readonly => true) do |record|
      assert record.readonly?
      found_numbers << record.value
    end
    assert_equal TOTAL_NUMBERS, found_numbers.size
    TOTAL_NUMBERS.times do |number|
      assert found_numbers.include?(number)
    end
  end
  
  def test_base_find_all_with_block_and_conditions
    found_numbers = []
    Number.find(:all, :conditions => ['value < 10']) do |record|
      found_numbers << record.value
    end
    assert_equal 10, found_numbers.size
  end
  
  def test_base_find_all_without_block
    found_numbers = []
    Number.find(:all).each do |record|
      found_numbers << record.value
    end
    assert_equal TOTAL_NUMBERS, found_numbers.size
    TOTAL_NUMBERS.times do |number|
      assert found_numbers.include?(number)
    end
  end
  
  def test_base_find_by_sql_with_block
    found_numbers = []
    Number.find_by_sql("SELECT * FROM numbers") do |record|
      found_numbers << record.value
    end
    assert_equal TOTAL_NUMBERS, found_numbers.size
    TOTAL_NUMBERS.times do |number|
      assert found_numbers.include?(number)
    end
  end
  
  def test_base_find_by_sql_without_block
    found_numbers = []
    Number.find_by_sql("SELECT * FROM numbers").each do |record|
      found_numbers << record.value
    end
    assert_equal TOTAL_NUMBERS, found_numbers.size
    TOTAL_NUMBERS.times do |number|
      assert found_numbers.include?(number)
    end
  end
  
  def test_base_find_all_with_block_and_includes
    authors = []
    Author.find(:all, :include => :books, :order => 'name') do |author|
      authors << author
    end
    assert_equal 4, authors.size
    
    ken = authors[0]
    assert_equal "Ken Akamatsu", ken.name
    assert ken.books.loaded?
    assert_equal 2, ken.books.size
    assert_equal "Love Hina", ken.books[0].name
    assert_equal "Negima", ken.books[1].name
    
    masashi = authors[1]
    assert_equal "Masashi Kishimoto", masashi.name
    assert masashi.books.loaded?
    assert_equal 1, masashi.books.size
    assert_equal "Naruto", masashi.books[0].name
    
    rumiko = authors[2]
    assert_equal "Rumiko Takahashi", rumiko.name
    assert rumiko.books.loaded?
    assert_equal 3, rumiko.books.size
    assert_equal "Inu Yasha", rumiko.books[0].name
    assert_equal "Ranma 1/2", rumiko.books[1].name
    assert_equal "Urusei Yatsura", rumiko.books[2].name
    
    tsugumi = authors[3]
    assert_equal "Tsugumi Ohba", tsugumi.name
    assert tsugumi.books.loaded?
    assert_equal 1, tsugumi.books.size
    assert_equal "Death Note", tsugumi.books[0].name
  end
  
  def test_base_find_all_with_block_and_includes_and_join_conditions
    # It finds the right queries, but it cannot preload the associations
    # according to the join conditions, as is the case with the non-block
    # version.
    
    numbers = []
    Number.find(:all, :include => { :authors => :books },
      :conditions => ['books.tag = 0'], :order => 'numbers.value,authors.name,books.name') do |number|
      numbers << number
    end
    
    assert_equal 2, numbers.size
    
    zero = numbers[0]
    assert !zero.authors.loaded?
    assert_equal 1, zero.authors.size
    ken = zero.authors[0]
    assert_equal "Ken Akamatsu", ken.name
    assert_equal 2, ken.books.size  # Would be 1 in the non-block version.
    assert_equal "Love Hina", ken.books[0].name
    assert_equal "Negima", ken.books[1].name
    
    one = numbers[1]
    assert !one.authors.loaded?
    assert_equal 3, one.authors.size
    
    masashi = one.authors[0]
    assert_equal "Masashi Kishimoto", masashi.name
    assert_equal 1, masashi.books.size
    assert_equal "Naruto", masashi.books[0].name
    
    rumiko  = one.authors[1]
    assert_equal "Rumiko Takahashi", rumiko.name
    assert_equal 3, rumiko.books.size    # Would be 2 in the non-block version.
    assert_equal "Inu Yasha", rumiko.books[0].name
    assert_equal "Ranma 1/2", rumiko.books[1].name
    assert_equal "Urusei Yatsura", rumiko.books[2].name
  end
  
  def test_association_find_all_with_block
    one = Number.find_by_value(1)
    authors = []
    one.authors.find(:all) do |author|
      authors << author
    end
    assert !one.authors.loaded?
    assert_equal 3, authors.size
  end
  
  def test_association_each_when_target_not_loaded
    one = Number.find_by_value(1)
    authors = []
    one.authors.each do |author|
      authors << author
    end
    assert !one.authors.loaded?
    assert_equal 3, authors.size
  end
  
  def test_association_each_when_target_loaded
    one = Number.find_by_value(1)
    one.authors.reload
    
    copy = Number.find_by_value(1)
    copy.authors.create!(:name => 'Nobody')
    
    authors = []
    one.authors.each do |author|
      authors << author
    end
    assert_equal 3, authors.size
  end
  
  def test_association_each_on_unsaved_owner
    authors = []
    number = Number.new
    number.authors.build(:name => 'Nobody')
    number.authors.build(:name => 'Nobody')
    number.authors.each do |author|
      authors << author
    end
    assert_equal 2, authors.size
  end

  def test_association_each_doesnt_interfere_with_saving
    number = Number.new(:value => 1)
    a1 = number.authors.build(:name => 'Nobody')
    a1.books.build(:name => 'Book', :tag => 0)
    a1.books.build(:name => 'Book', :tag => 0)
    a2 = number.authors.build(:name => 'Nobody')
    a2.books.build(:name => 'Book', :tag => 0)
    number.save!
    number.reload
    assert_equal 2, number.authors.size
  end
end