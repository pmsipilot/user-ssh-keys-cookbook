raise Chef::Exceptions::ConfigurationError, 'No configuration for cookbook' if node['ssh_keys']['users'].nil? || node['ssh_keys']['users'].empty?

node['ssh_keys']['users'].each do |user, config|
  raise Chef::Exceptions::ConfigurationError, "No configuration for user #{user}" if config.nil? || config.empty?

  begin
    home = Dir.home(user)
  rescue
    raise Chef::Exceptions::ConfigurationError, "User #{user} does not exist"
  end

  directory "#{home}/.ssh" do
    owner user
    group user
    mode '0600'
    action :create

    not_if "test -e #{home}/.ssh"
  end

  databag = data_bag(config['databag'] || node['ssh_keys']['databag'])

  unless databag[user].nil? || databag[user].empty?
    databag[user].each do |key|
      file "#{home}/.ssh/#{key['id']}.pub" do
        owner user
        group user
        mode '0600'
        content key['pub']
      end

      file "#{home}/.ssh/#{key['id']}" do
        owner user
        group user
        mode '0600'
        content key['priv'].kind_of?(Array) ? key['priv'].join("\n") : key['priv']
      end
    end
  end

  unless config['authorized_keys'].nil? || config['authorized_keys'].empty?
    file "#{home}/.ssh/authorized_keys" do
      owner user
      group user
      mode '0600'
      action :create_if_missing
    end

    config['authorized_keys'].each_with_index do |key, index|
      ruby_block "#{user}_authorized_keys_#{index}" do
        block do
          File.open("#{home}/.ssh/authorized_keys", 'a') do |file|
            file << key
          end
        end
      end
    end
  end
end
