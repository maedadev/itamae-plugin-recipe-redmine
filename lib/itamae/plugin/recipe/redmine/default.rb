require_relative 'version'
version = ENV['REDMINE_VERSION'] || Itamae::Plugin::Recipe::Redmine::REDMINE_VERSION
insecure = ENV['INSECURE'] ? '--no-check-certificate' : ''

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
    wget #{insecure} https://www.redmine.org/releases/redmine-#{version}.tar.gz
  EOF
  not_if "test -e /opt/redmine/redmine-#{version}/INSTALLED || echo #{::File.read(::File.join(::File.dirname(__FILE__), "redmine-#{version}_sha256sum.txt")).strip} | sha256sum -c"
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

execute 'bundle install --without development test --path vendor/bundle' do
  cwd "/opt/redmine/redmine-#{version}"
  command <<-EOF
    set -eu
    bundle install --without development test --path vendor/bundle
    touch BUNDLED
  EOF
  not_if "test -e /opt/redmine/redmine-#{version}/BUNDLED"
end

link 'current' do
  user 'root'
  cwd '/opt/redmine'
  to "redmine-#{version}"
  force true
end

patch_file = "#{File.dirname(__FILE__)}/files/application.rb.diff"
if version == '4.2.6'
  execute 'apply patch to config.session_store :cookie_store ... secure:true' do
    command "patch -p1                <#{patch_file}"
    not_if  "patch -p1 -Rsf --dry-run <#{patch_file}"
    cwd     '/opt/redmine/current'
  end
else
  Itamae.logger.warn "patch(#{patch_file}) is just for redmine #{version}, skipped."
end
