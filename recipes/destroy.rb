include_recipe "postgresql-bdr-cluster::destroy_#{node['postgresql-bdr-cluster']['provisioning']['driver']}"
