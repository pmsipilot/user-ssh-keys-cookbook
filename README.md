# ssh-keys-cookbook

Deploys SSH keys

## Supported Platforms

* CentOS 6.5
* Debian 7

## Attributes

| Key         | Type       | Default    | Description                                           |
| :---------- |:---------- | :--------- | :---------------------------------------------------- |
| `databag`   | String     | `ssh_keys` | Databag where to search for keys                      |
| `users`     | Hash       | `{}`       | A list of users with names as key                     |

### Users

| Key                 | Type       | Default    | Description                                              |
| :------------------ |:---------- | :--------- | :------------------------------------------------------- |
| `databag`           | String     | `ssh_keys` | Databag where to search for keys                         |
| `authorized_keys`   | Array      | `[]`       | Array of strings representing authorized SSH public keys |

## Databag

The databag is an `Hash` with usernames as keys. Each user can have a list of keypairs (as an `Array`).
A keypais is described as follow:

| Key    | Type   | Default | Description                |
| :------|:------ | :------ | :------------------------- |
| `id`   | String | `nil`   | Arbitrary name for the key |
| `priv` | String | `nil`   | Public key content         |
| `pub`  | String | `nil`   | Private key content        |

## Usage

### ssh-keys::default

Include `ssh-keys` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[ssh-keys]"
  ]
}
```

#### Example databag

```json
{
    "bob": [
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
