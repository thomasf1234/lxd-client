# Lxd::Client

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/lxd/client`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lxd-client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lxd-client

## Usage

```
require 'lxd-client'

> lxc = LxdClient::Service.new('https://192.168.20.26:8443', client_key: '/home/myuser/.ssl/lxc-client.key', client_cert: '/home/myuser/.ssl/lxc-client.crt')

> lxc.certificates
 => ["/1.0/certificates/284694ef9d0bc86c43a80c13dc5cda4df111894265fb39e937d3b13c1abee7ed"]
> lxc.images


```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/lxd-client.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

