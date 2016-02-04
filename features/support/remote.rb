require "shellwords"

def run_remote( service, command, container_index = 0, do_capture = true )
  # `docker-compose run` would create a new container instance. Thus we must use `docker exec` which uses the already existing container.
  # Unfortunately, we have to fiddle with the container name.
  return run_command "docker exec #{get_containers_for(service)[container_index]} #{command}", do_capture
end

def run_remote_async( service, command, container_index = 0 )
  # `docker-compose run` would create a new container instance. Thus we must use `docker exec` which uses the already existing container.
  # Unfortunately, we have to fiddle with the container name.
  return run_command_async "docker exec #{get_containers_for(service)[container_index]} #{command}"
end

def repair_shellescape ( input )
  escaped = input
  escaped = escaped.gsub /\\\'\'\n\'\\\'/, "\n"
  escaped = escaped.gsub /\\\\\\\s/, " "
  return escaped
end

def run_remote_from_pipe( service, command, container_index = 0, do_capture = true )
  escaped = repair_shellescape Shellwords.escape Shellwords.escape @command_out
  return run_remote "cli", 'bash -c "echo \"' + escaped + '\" | ' + command + '"', container_index, do_capture
end

def connect_service( service, count = 9999 )
  count = [count, get_containers_for(service).length].min
  (0..count-1).each do |index|
    connect_service_by_index(service, index)
  end
end

def connect_service_by_index( service, index )
  status, out, err = run_remote service, "ip link set dev eth0 up", index, false
  assert status.success?, "Could not connect service #{service}."
end

def disconnect_service( service, count = 9999 )
  count = [count, get_containers_for(service).length].min
  (0..count-1).each do |index|
    disconnect_service_by_index(service, index)
  end
end

def disconnect_service_by_index( service, index )
  status, out, err = run_remote service, "ip link set dev eth0 down", index, false
  assert status.success?, "Could not disconnect service #{service}."
end

def add_service( service, increment )
  count = get_containers_for(service).length + increment
  status, out, err = run_command "docker-compose scale #{get_host service}=#{count}", false
  assert status.success?, "Could not add instances to service #{service}."
  update_links service
end

def remove_service( service, decrement )
  count = [get_containers_for(service).length - decrement, 0].max
  status, out, err = run_command "docker-compose scale #{get_host service}=#{count}", false
  assert status.success?, "Could not remove instances from service #{service}."
  update_links service
end

def start_service( service )
  # Please note: The --no-recreate option prevents restarting of the other containers.
  run_command "docker-compose up -d --no-recreate #{get_host service}", false

  # Wait until service is up
  (0..get_timeout).each do |i|
    status, out, err = run_command "docker ps | grep 'cucumber_#{get_host service}_' | wc -l"
    if out.chomp != "0"
      return
    end
    sleep 1
  end
  assert false, "Could not start service #{service}."
end

def kill_service( service )
  run_command "docker-compose kill #{service}"

  # Wait until service is down
  (0..get_timeout).each do |i|
    # TODO: The commented-out command is insufficient to track the time needed to kill a service.
    # The workaround below does only work for services that are linked with the checkout container.
    # We need a more general solution here!
    # status, out, err = run_command "docker ps | grep 'cucumber_#{service}_' | wc -l"
    status, out, err = run_remote "checkout", "ping -c1 -q -W1 #{service}"
    if status != 0
      return
    end
    sleep 1
  end
  assert false, "Could not stop service #{service}."
end

def get_all_containers
  status, out, err = run_command "docker ps", false
  docker_ps = out.split( /\n/ )
  index = docker_ps[0].index('NAMES')
  docker_ps.shift
  docker_ps.map! { |line| line[index..-1].strip }
end

def get_containers_for service
  matching_containers = get_all_containers.grep /^cucumber_#{get_host service}_/
end

def get_linked_services service
  linked_services = []
  # read yml and find containers that link to this service
  filename = ENV["COMPOSE_FILE"] || "docker-compose.yml"
  container_config = YAML::load(File.open(File.join(".", filename)))
  container_config.each do |config|
    if (! config[1]['links'].nil?) && config[1]['links'].include?(get_host service)
      linked_services << config[0]
    end
  end
  return linked_services
end

def update_links service
  _remove_links service
  _add_links service
end

def _remove_links service
  get_linked_services(service).each do |linked_service|
    get_containers_for(linked_service).each do |linked_container|
      # Remove host entries for all service containers. Please note: `sed -i` is not possible
      status, out, err = run_command "docker exec -t #{linked_container} bash -c \"sed -E '/[[:space:]](cucumber_)?#{get_host service}_/d' /etc/hosts > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts\"", false
      # For debugging only:
      status, out, err = run_command "docker exec -t #{linked_container} bash -c \"cat /etc/hosts\"", false
    end
  end
end

def _add_links service
  get_containers_for(service).each do |container|
    status, ip, err = run_command "docker inspect #{container}  | grep IPAddress | cut -d '\"' -f 4", false
    ip.chomp!
    host = container.gsub(/^cucumber_/, '')

    get_linked_services(service).each do |linked_service|
      get_containers_for(linked_service).each do |linked_container|
        status, out, err = run_command "docker exec -t #{linked_container} bash -c \"echo '#{ip} #{host} #{container}' >> /etc/hosts\"", false
        # For debugging only:
        status, out, err = run_command "docker exec -t #{linked_container} bash -c \"cat /etc/hosts\"", false
      end
    end
  end
end

def filter_logs service, filters, timeout = -1, grep_options = ""
  output = ""

  services = [ service ]

  # Accept single filer as String instead of an array with only one element
  if filters.kind_of? String
    filters = [ filters ]
  end

  filter_commands = ""
  filters.each do |filter|
    filter_commands = filter_commands + " | grep #{grep_options} '" + filter + "'"
  end

  containers = get_all_containers

  (0..get_timeout(timeout)).each do |i|
    services.each do |service|

      # Please note: Not using `docker-compose logs` because it does not return but keeps waiting for new messages
      get_containers_for(service).each do |container|
        status, out, err = run_command "docker logs #{container}" + filter_commands
        output = output + out
      end
    end
    if output != ""
      break
    end
    sleep 1
  end

  return output
end
