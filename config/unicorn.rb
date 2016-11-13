worker_processes 2
timeout 3500
preload_app true

root_dir = Dir.pwd

listen "/tmp/unicorn.sock", :backlog => 64
pid "#{root_dir}/tmp/pids/unicorn.pid"
stderr_path "#{root_dir}/log/unicorn.stderr.log"
stdout_path "#{root_dir}/log/unicorn.stdout.log"

before_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to sent QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end