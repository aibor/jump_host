# JumpHost module

## Why?

If you need temporary droplets in different locations.

## How?

This module is based on the `droplet_kit` gem.

You'll need a snapshot at DO that will be used as a base. You might
specify a particular one. If you don't, the first is taken.

Also you need SSH Keys set up, so you don't need to hassle about the
root password.

Third thing you need is an API key that has write permission at DO.

In order to deploy and drop droplets easily via cli, a bash function
can be added to you shell rc. Make sure to replace the variable values
to match your needs.

```bash
# .bashrc
jump_host() {
  # you might need to adjust the path to your setup
  ruby -I$HOME/jump_host -rjump_host <<-EOC
  
  # format string for the hostname, %s is replaced with the region
  JumpHost::Droplet.name_format = "jump-%s.your-do.host"

  # replace with your API key
  JumpHost::DOApi.token =
  '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'

  # optional, first snapshot taken if this is not set
  JumpHost::Droplet.default_image_name = "my_jump_host_image"

  puts JumpHost::Droplet.send("$1", "$2")
EOC
}
```

Need a droplet in New York? Create it
```bash
$ jump_host deploy nyc1
new
1.2.3.4
```

Forgot the IP? Show it again
```bash
$ jump_host show nyc1
new
1.2.3.4
```

Work done? Drop it
```bash
$ jump_host drop nyc1
true
```

If something goew wrong, you'll see more or less helpful Ruby exceptions.

If you don't like or need such a simple bash function, take a look at
the code and use it in your ruby scripts.
