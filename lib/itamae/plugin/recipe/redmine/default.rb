include_recipe 'postgresql'

require_relative 'version'
version = ENV['REDMINE_VERSION'] || Itamae::Plugin::Recipe::Redmine::REDMINE_VERSION

%w{
  ImageMagick
  ImageMagick-devel
  expect
  ipa-pgothic-fonts
  libcurl-devel
  libffi-devel  
  libyaml-devel
  openssl-devel
  readline-devel
  zlib-devel
}.each do |name|
  package name do
    user 'root'
  end
end

directory '/opt/redmine' do
  user 'root'
  owner ENV['USER']
  group ENV['USER']
  mode '755'
end

directory '/opt/redmine/tmp' do
  user 'root'
  owner ENV['USER']
  group ENV['USER']
  mode '755'
end

execute "download redmine-#{version}" do
  cwd '/opt/redmine/tmp'
  command <<-EOF
    wget http://www.redmine.org/releases/redmine-#{version}.tar.gz
  EOF
  not_if "echo #{::File.read(::File.join(::File.dirname(__FILE__), "redmine-#{version}_sha256sum.txt")).strip} | sha256sum -c"
end

execute "build redmine-#{version}" do
  cwd '/opt/redmine/tmp'
  command <<-EOF
    set -eu
    rm -Rf redmine-#{version}/
    tar zxf redmine-#{version}.tar.gz
    rm -Rf /opt/redmine/redmine-#{version}/
    mv redmine-#{version} /opt/redmine/
    touch /opt/redmine/redmine-#{version}/INSTALLED
  EOF
  not_if "test -e /opt/redmine/redmine-#{version}/INSTALLED"
end

template "/opt/redmine/redmine-#{version}/config/configuration.yml" do
  user 'root'
  owner ENV['USER']
  group ENV['USER']
  mode '644'
end

template "/opt/redmine/redmine-#{version}/config/database.yml" do
  owner ENV['USER']
  group ENV['USER']
  mode '644'
  variables redmine_password: ENV['REDMINE_PASSWORD'] || 'redmine'
end

execute 'createuser' do
  command "sh #{::File.join(File.dirname(__FILE__), 'create_user.sh')} #{ENV['REDMINE_PASSWORD'] || 'redmine'}"
  not_if "sudo -u postgres psql -c \"select * from pg_user where usename = 'redmine';\" | grep redmine"
end

execute 'createdb -E UTF-8 -l ja_JP.UTF-8 -O redmine -T template0 redmine' do
  user 'postgres'
  not_if "psql -c \"select * from pg_database where datname = 'redmine';\" | grep redmine"
end

gem_package 'bundler' do
  user 'root'
  version '1.17.3'
end

execute 'bundle _1.17.3_ install --without development test --path vendor/bundle' do
  cwd "/opt/redmine/redmine-#{version}"
  command <<-EOF
    set -eu
    bundle _1.17.3_ install --without development test --path vendor/bundle
    touch BUNDLED
  EOF
  not_if "test -e /opt/redmine/redmine-#{version}/BUNDLED"
end

execute 'redmine initialization' do
  cwd "/opt/redmine/redmine-#{version}"
  command <<-EOF
    set -eu
    bundle exec rake generate_secret_token
    bundle exec rake db:migrate RAILS_ENV=production
    touch INITIALIZED
  EOF
  not_if "test -e /opt/redmine/redmine-#{version}/INITIALIZED"
end

link 'current' do
  user 'root'
  cwd '/opt/redmine'
  to "redmine-#{version}"
  force true
end
