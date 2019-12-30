namespace :load do
  task :defaults do
    set_if_empty :gate_config_name, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
    set_if_empty :nginx_sites_available_path, '/etc/nginx/sites-available'
    set_if_empty :nginx_sites_enabled_path, '/etc/nginx/sites-enabled'
  end
end

namespace :gate do
  %i[stop start restart reload force-reload].each do |action|
    desc "#{action.to_s.capitalize} gate"
    task action do
      on roles :gate do
        sudo :service, 'nginx', action.to_s
      end
    end
  end

  desc 'Setup gate'
  task :setup do
    def sudo_upload!(from, to)
      filename = File.basename(to)
      to_dir = File.dirname(to)
      tmp_file = "#{fetch(:tmp_dir)}/#{filename}"

      upload! from, tmp_file
      sudo :mv, tmp_file, to_dir
    end

    on roles :gate do
      template = File.read File.expand_path "../../templates/gate.erb", __FILE__
      config = StringIO.new(ERB.new(template, nil, '-').result(binding))
      available = File.join(fetch(:nginx_sites_available_path), fetch(:gate_config_name))
      enabled = File.join(fetch(:nginx_sites_enabled_path), fetch(:gate_config_name))

      sudo_upload! config, available
      sudo :ln, '-fs', "#{available} #{enabled}"
    end
  end
end