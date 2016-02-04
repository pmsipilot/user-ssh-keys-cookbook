# user-ssh-keys-cookbook [![Build Status](https://travis-ci.org/pmsipilot/user-ssh-keys-cookbook.svg?branch=master)](https://travis-ci.org/pmsipilot/user-ssh-keys-cookbook)

Deploys SSH keys and authorized keys

## Supported Platforms

* CentOS 6.5
* Debian 7

## Attributes

The root key of all attributes is `user_ssh_keys`.

| Key         | Type       | Default    | Description                                           |
| :---------- |:---------- | :--------- | :---------------------------------------------------- |
| `data_bag`  | String     | `ssh_keys` | Databag where to search for keys                      |
| `users`     | Hash       | `{}`       | A list of users with names as key                     |

### Users

| Key                 | Type       | Default    | Description                                                                       |
| :------------------ |:---------- | :--------- | :-------------------------------------------------------------------------------- |
| `authorized_keys`   | Array      | `[]`       | Array of strings representing authorized SSH public keys                          |
| `authorized_users`  | Array      | `[]`       | Array of strings representing authorized users (found in the [databag](#databag)) |

## LWRP

This cookbook provides one resource:

### `user_ssh_keys_key`

```ruby
user_ssh_keys_key 'john' do
  authorized_keys [
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmz4D...',
    'ssh-rsa sFE5JafGV4UmfxGP5/vpAAADWC8HcoQAyYT...'
  ]
  authorized_users %w(bob joe)
end

```

This resource will add authorized keys from the provided list (`authorized_keys`) and from users declared in the databag (`bob` and `joe`) to the `john` user.

## Databag

The databag is a `Hash` with usernames as keys. Each user can have a list of keypairs (as an `Array`).
A keypair is described as follow:

| Key    | Type   | Default | Description                |
| :------|:------ | :------ | :------------------------- |
| `id`   | String | `nil`   | Arbitrary name for the key |
| `priv` | String | `nil`   | Public key content         |
| `pub`  | String | `nil`   | Private key content        |

## Usage

You can use this cookbook in two ways:

* using the [default](#user-ssh-keys-default) recipe and providing (attributes)[#attributes]
* using the [LWRP](#lwrp) 

Both methods require you to define a [databag](#databag) to define SSH key pairs. Defining attributes is not required if you only want to use the LWRP.

Note that the user whose keys you wish to populate must already exist,
and *also* have a databag entry.  That is, if you have:

```ruby
user_ssh_keys_key 'root' do
  authorized_users %w(bob)
  data_bag 'keys'
  action :create
end
```

then you must have a databag entry for both "bob" *and* "root".

### user-ssh-keys::default

Include `user-ssh-keys` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[user-ssh-keys]"
  ]
}
```

#### Example databag

```json
{
    "id": "bob",
    "keys": [
        {
            "id": "my_key",
            "pub": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmz4D...",
            "priv": [
                "-----BEGIN RSA PRIVATE KEY-----",
                "MIIEpgIBAAKCAQEA5s+A461t/v8mQB9UQpaYwGWNl...",
                "...",
                "-----END RSA PRIVATE KEY-----"
            ]
        },
        {
            "id": "my_other_key",
            "pub": "ssh-rsa sFE5JafGV4UmfxGP5/vpWC8HcoQAyYT...",
            "priv": [
                "-----BEGIN RSA PRIVATE KEY-----",
                "XFQg/FfgRC+rwooxKXsxqjA/zapfkzFVBchsjmYpx...",
                "...",
                "-----END RSA PRIVATE KEY-----"
            ]
        }
    ]
}

```
