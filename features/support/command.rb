require 'open3'

def run_command( command, do_capture = true )
  command_out, command_err, command_status = Open3.capture3(command)
  if do_capture
    @command = command
    @command_out = command_out
    @command_err = command_err
    @command_status = command_status
  end

  if ENV['LOG']  == 'debug'
    puts "Command: #{command}"
    puts "Status: #{command_status}"
    puts "Stdout: #{command_out}"
    puts "Stderr: #{command_err}"
    if do_capture
      puts "Output saved for later use."
    end
  end

  return command_status, command_out, command_err
end

def run_command_async( command )
  *streams, @command_handle = Open3.popen3(command)
end
