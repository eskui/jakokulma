namespace :thinking_sphinx do

  def args
    fetch(:thinking_sphinx_args, ":")
  end

  def thinking_sphinx_roles
    fetch(:thinking_sphinx_server_role, :app)
  end

  desc 'Stop the thinking_sphinx process'
  task :stop do
    on roles(thinking_sphinx_roles) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :rake, :'ts:stop'
        end
      end
    end
  end

  desc 'Start the thinking_sphinx process'
  task :start do
    on roles(thinking_sphinx_roles) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :rake, :'ts:start'
        end
      end
    end
  end

  desc 'Restart the thinking_sphinx process'
  task :restart do
    on roles(thinking_sphinx_roles) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :rake, :'ts:rebuild'
        end
      end
    end
  end

end