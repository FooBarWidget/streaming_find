Iterate over SQL result sets without slurping everything into memory
====================================================================

Suppose you have this code:

    User.find(:all).each do |user|
        do_something_with(user)
    end

If you have 1 million users then ActiveRecord will slurp all 1 million rows into memory. Ouch. Even low-level methods like `ActiveRecord::Base.connection.select_values` suffer from this problem.

The `streaming_find` plugin provides an interface allowing you to stream over the result set one-by-one, without loading everything into memory. Pass a block to a find function and it will call the block for each result.

    User.find(:all) do |user|
        do_something_with(user)
    end
    
    User.find_by_sql(...) do |row|
        do_something_with(row)
    end

It also changes the behavior of the `#each` method on associations.

    # Instead of slurping all 5000 friends into memory,
    # streaming_find will ensure only one is retrieved at a time.
    user.friends.each do |friend|
        do_something_with(friend)
    end

It also modifies `ActiveRecord::Base.connection.select_all`. If you pass it a block then `#select_all` will call it the block for every result.

    ActiveRecord::Base.connection.select_all("select * from users") do |row|
        do_something_with(row)
    end


streaming\_find vs find\_in\_batches
------------------------------------

`find_in_batches` is pretty bad for performance. It runs the same query multiple times, each time with a different OFFSET and LIMIT. For every batch the database needs to skip over OFFSET items. `find_in_batches` essentially implements a [Schlemiel the Painter's algorithm](http://en.wikipedia.org/wiki/Schlemiel_the_Painter%27s_algorithm).

`streaming_find` doesn't do that. It executes the query once and loads the results one by one. For every row it calls the block, then discards it and moves on to the next. But see the notes below.


Supported adapters
------------------

Only MySQL and SQLite are supported at this time. Please contribute to have more adapters supported.

Note however that even though `streaming_find` does its best to load results one-by-one, the Ruby MySQL driver still loads the entire result set into memory. However this amount of memory is fairly small compared to what ActiveRecord would otherwise use, so it's still a win. We've tested this in production with queries that return tens of thousands of rows, and the system could handle it fine.