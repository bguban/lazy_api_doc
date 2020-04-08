# LazyApiDoc

A library to generate OpenAPI V3 documentation from tests. 

LazyApiDoc collects requests and responses from your controller and request specs, retrieves data types, optional 
attributes, endpoint description and then generates OpenAPI documentation. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lazy_api_doc', group: :test
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install lazy_api_doc

Then run install task

    $ rails g lazy_api_doc:install

## Usage

Update files `public/lazy_api_doc/index.html` and `public/lazy_api_doc/layout.yml`. These files will be 
used as templates to show the documentation. You need to set your application name, description and
so on.

And just run your tests with `DOC=true` environment variable:

    $ DOC=true rspec

or

    # DOC=true rake test

The documentation will be placed `public/lazy_api_doc/api.yml`. To see it just run server

    $ rails server
    
and navigate to http://localhost:3000/lazy_api_doc/

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bguban/lazy_api_doc. This project is intended 
to be a safe, welcoming space for collaboration, and contributors are expected to adhere to 
the [code of conduct](https://github.com/bguban/lazy_api_doc/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LazyApiDoc project's codebases, issue trackers, chat rooms and mailing lists is expected to 
follow the [code of conduct](https://github.com/bguban/lazy_api_doc/blob/master/CODE_OF_CONDUCT.md).
