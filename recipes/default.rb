raise Chef::Exceptions::ConfigurationError, 'No configuration for cookbook' if node['ssh_keys']['users'].nil? || node['ssh_keys']['users'].empty?

node['ssh_keys']['users'].each do |username, user|
  user = PMSIpilot::SshKeys::User.normalize!(
    username,
    user,
    node,
    Proc.new do |name|
      data_bag(name)
    end
  )

  directory "#{user['home']}/.ssh" do
    owner username
    group username
    mode '0600'
    action :create

    not_if "test -e #{user['home']}/.ssh"
  end

  user['keys'].each do |key|
    key = PMSIpilot::SshKeys::Key.normalize!(key)

    file "#{user['home']}/.ssh/#{key['id']}.pub" do
      owner username
      group username
      mode '0600'
      content key['pub']
      not_if { key['pub'].empty? }
    end

    file "#{user['home']}/.ssh/#{key['id']}" do
      owner username
      group username
      mode '0600'
      content key['priv'].kind_of?(Array) ? key['priv'].join("\n") : key['priv']
    end
  end

  template "#{user['home']}/.ssh/authorized_keys" do
    source 'authorized_keys.erb'
    owner username
    group username
    mode '0600'
    variables keys: user['authorized_keys']
  end
end
