require_relative 'version'

version = ENV['REDMINE_VERSION'] || Itamae::Plugin::Recipe::Redmine::REDMINE_VERSION

%w{
  ImageMagick
  ImageMagick-devel
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

user 'redmine' do
  user 'root'
  system_user true
  home '/opt/redmine/current'
end

directory '/opt/redmine' do
  user 'root'
  owner 'redmine'
  group 'redmine'
  mode '755'
end

directory '/opt/redmine/tmp' do
  user 'root'
  owner ENV['USER']
  group 'redmine'
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
    sudo rm -Rf /opt/redmine/redmine-#{version}/
    sudo mv redmine-#{version} /opt/redmine/
    sudo chown -R redmine:redmine /opt/redmine/redmine-#{version}
    sudo -u redmine touch /opt/redmine/redmine-#{version}/INSTALLED
  EOF
  not_if "test -e /opt/redmine/redmine-#{version}/INSTALLED"
end

%w{
  configuration.yml
  database.yml
}.each do |name|
  template "/opt/redmine/redmine-#{version}/config/#{name}" do
    user 'root'
    owner 'redmine'
    group 'redmine'
    mode '644'
  end
end

gem_package 'bundler' do
  user 'root'
  version '1.17.3'
end

execute 'bundle _1.17.3_ install --without development test --path vendor/bundle' do
  cwd "/opt/redmine/redmine-#{version}"
  user 'redmine'
end

link 'current' do
  user 'root'
  cwd '/opt/redmine'
  to "redmine-#{version}"
  force true
end
