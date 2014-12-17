node['ssh_keys']['users'].each do |username, user|
  ssh_keys_key username do
    authorized_keys user['authorized_keys']
    authorized_users user['authorized_users']
    data_bag node['ssh_keys']['data_bag']
    action :create
  end
end
