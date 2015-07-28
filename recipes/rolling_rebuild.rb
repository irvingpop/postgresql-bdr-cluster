include_recipe "postgresql-bdr-cluster::rolling_rebuild_#{node['postgresql-bdr-cluster']['provisioning']['driver']}"
