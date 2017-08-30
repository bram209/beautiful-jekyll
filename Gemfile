source 'https://rubygems.org'

require 'json'
require 'open-uri'
versions = JSON.parse(open('https://pages.github.com/versions.json').read)

gem 'github-pages', versions['github-pages']

gem 'jekyll-paginate', versions['github-paginate']
gem 'jekyll-compose', group: [:jekyll_plugins]

group :development do
  gem 'guard-livereload', '~> 2.5', require: false
end