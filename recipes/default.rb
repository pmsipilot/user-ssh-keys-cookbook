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

  authorized_keys = config['authorized_keys']
  authorized_keys ||= []

  unless config['authorized_users'].nil? || config['authorized_users'].empty?
    config['authorized_users'].each do |authorized_user|
      raise Chef::Exceptions::ConfigurationError, "User #{authorized_user} does not exist" if databag[authorized_user].nil?

      databag[authorized_user].each do |authorized_user_key|
        authorized_keys << authorized_user_key['pub']
      end
    end
  end

  unless authorized_keys.empty?
    template "#{home}/.ssh/authorized_keys" do
      source 'authorized_keys.erb'
      owner user
      group user
      mode '0600'
      variables keys: authorized_keys
    end
  end
end
