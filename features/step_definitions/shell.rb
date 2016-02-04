Given(/^there is a shell$/) do
  start_service "cli"
end

When(/^I run the command `(.+)`$/) do |commandline|
  run_remote "cli", commandline
end

When(/^I pipe the output of the command to `(.+)`$/) do |commandline|
  run_remote_from_pipe "cli", commandline
end
