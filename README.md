# postgresql-bdr-cluster Chef cookbook

An MVP Chef cookbook for configuring a PostgreSQL BDR cluster, using Chef Provisioning

# Requirements

* ChefDK 0.6.0 or greater
  * Follow [the instructions](https://docs.chef.io/install_dk.html) to set ChefDK as your system Ruby and Gemset
* Vagrant and Virtualbox (for now)

# Using it

Starting up a cluster:
```bash
rake up
```

Connecting to your cluster nodes:
```bash
cd vagrants ; vagrant ssh postgresql-bdr1.example.com
```

Destroying the cluster
```bash
rake destroy
```

Perform a rolling rebuild of the cluster:
```bash
rake rolling_rebuild
```

# TODO
* AWS or other cloud support
