raise Chef::Exceptions::ConfigurationError, 'No configuration for cookbook' if node['ssh_keys']['users'].nil? || node['ssh_keys']['users'].empty?

node['ssh_keys']['users'].each do |user, config|
  config = PMSIpilot::SshKeys::User.normalize!(
    user,
    config,
    node,
    Proc.new do |name|
      data_bag(name)
    end
  )

  directory "#{config['home']}/.ssh" do
    owner user
    group user
    mode '0600'
    action :create

    not_if "test -e #{config['home']}/.ssh"
  end

  config['keys'].each do |key|
    key = PMSIpilot::SshKeys::Key.normalize!(key)

    file "#{config['home']}/.ssh/#{key['id']}.pub" do
      owner user
      group user
      mode '0600'
      content key['pub']
      not_if { key['pub'].empty? }
    end

    file "#{config['home']}/.ssh/#{key['id']}" do
      owner user
      group user
      mode '0600'
      content key['priv'].kind_of?(Array) ? key['priv'].join("\n") : key['priv']
    end
  end

  template "#{config['home']}/.ssh/authorized_keys" do
    source 'authorized_keys.erb'
    owner user
    group user
    mode '0600'
    variables keys: config['authorized_keys']
  end
end
