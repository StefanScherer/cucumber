Then(/^the command should (succeed|fail)$/) do |condition|
  expected = condition == "succeed" ? true : false
  assert_equal expected, @command_status.success?, "Command exited with status #{@command_status}"
end

Then(/^the (output|error output) of the command should(| not)(?:| also) be ['"](.*)['"]$/) do |stream, condition, expected|

  stream.downcase!

  actual = @command_out.chomp
  if (stream == "error output")
    actual = @command_err.chomp
  end
  is_equal = ( actual == expected )

  should_be_equal = condition != ' not'

  if is_equal and !should_be_equal
    raise "#{stream} is \"#{actual}\", but it shouldn't"
  end

  if !is_equal and should_be_equal
    raise "#{stream} is \"#{actual}\", but it should be \"#{expected}\""
  end
end

Then(/^the (output|error output) of the command should(| not)(?:| also) contain ['"](.*)['"]$/) do |stream, condition, expected|

  stream.downcase!

  actual = @command_out.chomp
  if (stream == "error output")
    actual = @command_err.chomp
  end
  it_contains = ( actual.include? expected )

  should_contain = condition != ' not'

  if it_contains and !should_contain
    raise "#{stream} is \"#{actual}\", but it shouldn't contain \"#{expected}\""
  end

  if !it_contains and should_contain
    raise "#{stream} is \"#{actual}\", but it should contain \"#{expected}\""
  end
end

Then(/^the (output|error output) of the command should(| not)(?:| also) match the regex ['"](.*)['"]$/) do |stream, condition, pattern|

  stream.downcase!

  actual = @command_out.chomp
  if (stream == "error output")
    actual = @command_err.chomp
  end
  it_contains = ( /#{pattern}/ =~ actual  )

  should_contain = condition != ' not'

  if it_contains and !should_contain
    raise "#{stream} is \"#{actual}\", but it shouldn't match /\"#{pattern}\"/"
  end

  if !it_contains and should_contain
    raise "#{stream} is \"#{actual}\", but it should match /\"#{pattern}\"/"
  end
end
