require_relative 'version'
version = ENV['REDMINE_VERSION'] || Itamae::Plugin::Recipe::Redmine::REDMINE_VERSION
insecure = ENV['INSECURE'] ? '--no-check-certificate' : ''

%w{
  expect
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

case "#{node.platform_family}-#{node.platform_version}"
when /rhel-7\.(.*?)/
  %w{
    ipa-pgothic-fonts
  }.each do |name|
    package name do
      user 'root'
    end
  end

  %w{
    ImageMagick
    ImageMagick-devel
  }.each do |name|
    package name do
      user 'root'
      options '--enablerepo=epel'
    end
  end
when /rhel-8\.(.*?)/
  %w{
    google-noto-sans-cjk-jp-fonts
  }.each do |name|
    package name do
      user 'root'
    end
  end

  %w{
    ImageMagick
    ImageMagick-devel
  }.each do |name|
    package name do
      user 'root'
      options '--enablerepo=epel'
    end
  end
else
  raise 'サポート対象外のOSです。'
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

if ENV['GEMFILE_LOCAL'] || %w{4.1.7 4.2.11}.include?(version)
  template "/opt/redmine/redmine-#{version}/Gemfile.local" do
    user 'root'
    owner ENV['USER']
    group ENV['USER']
    mode '644'
    source ENV['GEMFILE_LOCAL'] || ::File.join(::File.dirname(__FILE__), "templates/#{version}/Gemfile.local.erb")
  end
end

execute 'bundle install' do
  cwd "/opt/redmine/redmine-#{version}"
  command <<-EOF
    set -eu
    bundle config set --local without 'itamae development test'
    bundle install -j2
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
