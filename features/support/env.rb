require 'test/unit'
require 'minitest'
require_relative 'command.rb'

World(MiniTest::Assertions)

ENV["CUCUMBER_ROOT"] = Dir.pwd

def main
  # Kill containers before we run the cucumber tests
  stop_system
end

def stop_system
  status, out, err = run_command "docker-compose kill; docker-compose rm -vf"
end

def get_timeout min_timeout = 0, max_timeout = 999
  if min_timeout <= 0
    min_timeout = 30
  end

  timeout = ENV['TIMEOUT'] ? [ENV['TIMEOUT'].to_i, min_timeout].max : min_timeout
  return [timeout, max_timeout].min
end

def get_host service
  return service
end

def dump_last_command scenario
  if scenario.failed?
    print "\n--- LAST COMMAND - START ---\n\n"
    print "Command: #{@command}\n"
    print "Status: #{@command_status}\n"
    print "Stdout: #{@command_out}\n"
    print "Stderr: #{@command_err}\n"
    print "\n--- LAST COMMAND - END ---\n"
  end
end

def dump_logs scenario
end

def rollback_system
  if ENV['NOROLLBACK']
    print "--- Saw NOROLLBACK environment. Not rolling back. ---\n"
  else
    stop_system
  end
end

After('~@norollback') do |scenario|
  dump_logs scenario
  if scenario.failed?
    if ENV['ONERROR'] == 'ignore'
      rollback_system
    elsif ENV['ONERROR'] == 'stop'
      Cucumber.wants_to_quit = true
    else # Default: Wait
      print "--- Execution paused. Please press Enter to continue. ---\n"
      STDOUT.flush
      STDIN.getc
      rollback_system
    end
  else
    rollback_system
  end
end

After('@norollback') do |scenario|
  dump_logs scenario

  if scenario.failed?
    if ENV['ONERROR'] == 'ignore'
      # Do nothing
    elsif ENV['ONERROR'] == 'stop'
      Cucumber.wants_to_quit = true
    else # Default: Wait
      print "--- Execution paused. Please press Enter to continue. ---\n"
      STDOUT.flush
      STDIN.getc
    end
  end

  print "--- Saw @norollback tag. Not rolling back. ---\n"
end

# Workaround for missing @ignore tag which comes with new cucumber version
Given(/^pending$/) do
  pending
end

main
