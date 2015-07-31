cluster_nodes_count = 3
default['postgresql-bdr-cluster']['cluster_nodes'] = 1.upto(cluster_nodes_count).map { |i| "postgresql-#{i}.example.com" }

# Provisiong driver settings
default['postgresql-bdr-cluster']['provisioning']['driver'] = 'aws'

# Vagrant settings
default['chef-provisioning-vagrant']['vbox']['box'] = 'box-cutter/centos71'
default['chef-provisioning-vagrant']['vbox']['ram'] = 512
default['chef-provisioning-vagrant']['vbox']['cpus'] = 1
default['chef-provisioning-vagrant']['vbox']['private_networks']['default'] = 'dhcp'

# AWS settings
default['chef-provisioning-aws']['region'] = 'us-west-2'
default['chef-provisioning-aws']['ssh_username'] = 'ec2-user'
default['chef-provisioning-aws']['instance_type'] = 'c3.xlarge'
default['chef-provisioning-aws']['ebs_optimized'] = true
default['chef-provisioning-aws']['image_id'] = 'ami-4dbf9e7d' # RHEL 7.1 2015-02
default['chef-provisioning-aws']['subnet_id'] = 'subnet-b2bb82f4'
default['chef-provisioning-aws']['keypair_name'] = "#{ENV['USER']}@postgresql-bdr-cluster"

# Postgres settings
default['postgresql-bdr-cluster']['bdr_dbnames'] = %w(opscode_chef bifrost opscode_reporting oc_id)

default['postgresql']['dir'] = '/var/lib/pgsql/9.4-bdr/data'

default['postgresql']['config']['data_directory'] = node['postgresql']['dir']
default['postgresql']['config']['listen_addresses'] = '*'
default['postgresql']['config']['port'] = 5432
default['postgresql']['config']['max_connections'] = 100
default['postgresql']['config']['shared_buffers'] = '128MB'
default['postgresql']['config']['dynamic_shared_memory_type'] = 'posix'
default['postgresql']['config']['log_destination'] = 'stderr'
default['postgresql']['config']['logging_collector'] = true
default['postgresql']['config']['log_directory'] = 'pg_log'
default['postgresql']['config']['log_filename'] = 'postgresql-%a.log'
default['postgresql']['config']['log_truncate_on_rotation'] = true
default['postgresql']['config']['log_rotation_age'] = '1d'
default['postgresql']['config']['log_rotation_size'] = 0
default['postgresql']['config']['log_line_prefix'] = '< %m >'
default['postgresql']['config']['log_timezone'] = 'UTC'
default['postgresql']['config']['datestyle'] = 'iso, mdy'
default['postgresql']['config']['timezone'] = 'UTC'
default['postgresql']['config']['lc_messages'] = 'en_US.UTF-8'
default['postgresql']['config']['lc_monetary'] = 'en_US.UTF-8'
default['postgresql']['config']['lc_numeric'] = 'en_US.UTF-8'
default['postgresql']['config']['lc_time'] = 'en_US.UTF-8'
default['postgresql']['config']['default_text_search_config'] = 'pg_catalog.english'

default['postgresql']['config']['effective_cache_size'] = "#{(node['memory']['total'].to_i / 2) / (1024)}MB"
default['postgresql']['config']['checkpoint_segments'] = '64'
default['postgresql']['config']['checkpoint_timeout'] = '5min'
default['postgresql']['config']['checkpoint_completion_target'] = '0.9'
default['postgresql']['config']['checkpoint_warning'] = '30s'

# BDR recommended settings
default['postgresql']['config']['shared_preload_libraries'] = 'bdr'
default['postgresql']['config']['wal_level'] = 'logical'
default['postgresql']['config']['track_commit_timestamp'] = true
default['postgresql']['config']['max_wal_senders'] = '20'
default['postgresql']['config']['max_replication_slots'] = '20'
default['postgresql']['config']['max_worker_processes'] = '20'
default['postgresql']['config']['log_error_verbosity'] = 'verbose'
default['postgresql']['config']['log_min_messages'] = 'debug1'
# default['postgresql']['config']['log_line_prefix'] = 'd=%d p=%p a=%a%q '
default['postgresql']['config']['bdr.log_conflicts_to_table'] = true


default['postgresql']['pg_hba'] = [
  {:type => 'local', :db => 'all', :user => 'postgres', :addr => nil, :method => 'ident'},
  {:type => 'local', :db => 'all', :user => 'all', :addr => nil, :method => 'ident'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '127.0.0.1/32', :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '::1/128', :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '0.0.0.0/0', :method => 'md5'},
  {:type => 'local', :db => 'replication', :user => 'postgres', :addr => nil, :method => 'ident'},
  {:type => 'host', :db => 'replication', :user => 'postgres', :addr => '127.0.0.1/32', :method => 'md5'},
  {:type => 'host', :db => 'replication', :user => 'postgres', :addr => '::1/128', :method => 'md5'},
  {:type => 'host', :db => 'replication', :user => 'replication', :addr => '0.0.0.0/0', :method => 'md5'}
]
