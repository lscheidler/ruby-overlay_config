# OverlayConfig

[![Build Status](https://travis-ci.org/lscheidler/ruby-overlay_config.svg?branch=master)](https://travis-ci.org/lscheidler/ruby-overlay_config)

Application config with overlay functionality.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'overlay_config', git: 'https://github.com/lscheidler/ruby-overlay_config'
```

And then execute:

    $ bundle

## Usage

### application config with defaults

```ruby
require 'bundler/setup'
require 'overlay_config'

@config = OverlayConfig::Config.new(
  config_scope: 'my_application',
  defaults: {
    default_a: 'This is default a'
  }
)

# search for 'entry' and :entry in config files and return the first value found
@config.get(:entry)
@config[:entry]

# set config in defaults hash
@config[:default_b] = 'This is default b'

# check, if config has a specific key
@config.has_key? :default_a
=> true

# search for 'doesntexist' and :doesntexist in config files and return default, if not found
@config.get(:doesntexist, default: 'default value')
```

Will look for following config files in this order:

- $HOME/.config/my\_application/config.json
- $HOME/.config/my\_application/credentials.json
- /etc/my\_application/config.json
- /etc/my\_application/credentials.json

and parses all files, which are found.

### application config with alternative config files and directories

```ruby
require 'bundler/setup'
require 'overlay_config'

@config = OverlayConfig::Config.new(
  config_scope: 'my_application',
  config_base_directories: ['/usr/local/etc'],
  config_filenames: ['config.json', 'override.json']
)
```

Will look for following config files in this order:

- /usr/local/etc/my\_application/config.json
- /usr/local/etc/my\_application/override.json

### application config with alternative config file extensions

```ruby
require 'bundler/setup'
require 'overlay_config'

@config = OverlayConfig::Config.new(
  config_scope: 'my_application',
  config_filenames: ['config.cfg'],
  default_parser: :yaml
)
```

Will look for following config files in this order and parse it as YAML:

- $HOME/.config/my\_application/config.cfg
- /etc/my\_application/config.cfg

Alternatively you can set the parser to :json, if config file is in JSON format.

### Log missing or unsupported config files to Logger object

```ruby
require 'bundler/setup'
require 'overlay_config'

log = Logger.new $stdout
log.level = Logger::INFO

@config = OverlayConfig::Config.new(
  log: log
)
```

### Add external loaded configuration to config object

```ruby
require 'bundler/setup'
require 'overlay_config'

@config = OverlayConfig::Config.new(defaults: {
  default_value: '133'
})

# insert config before defaults in config file list
@config.insert(@config.length-1, '<filename>', {
  setting: 'value'
})

# append config to the end of config file list
@config.append('<filename>', {
  setting: 'value'
})
```

### Hash extension

```ruby
require 'bundler/setup'
require 'overlay_config'

@hash = {
  symbol: 'Hello Symbol World',
  'string' => 'Hello String World',
  hash: {
    'cascade' => {
      final: 'inner value'
    }
  }
}

@hash.get :symbol
=> "Hello String World"

@hash.get 'symbol'
=> "Hello String World"

@hash.get [:hash, :cascade, 'final']
=> "inner value"

@hash.get :doesntexist, default: 'default value'
=> "default value"

@hash.get [:hash, :cascade, :doesntexist], default: 'default value'
=> "default value"

@hash.get :doesntexist
=> nil
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lscheidler/ruby-overlay_config.
## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

