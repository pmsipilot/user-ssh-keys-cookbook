actions :create, :delete
default_action :create

attribute :username,
          :kind_of => String,
          :required => true,
          :name_attribute => true

attribute :data_bag,
          :kind_of => String,
          :default => 'ssh_keys'

attribute :authorized_keys,
          :kind_of => Array,
          :default => []

attribute :authorized_users,
          :kind_of => Array,
          :default => []
