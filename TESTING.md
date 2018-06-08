## Testing Prerequisites

Hashicorp's [Vagrant](https://www.vagrantup.com/downloads.html) and Oracle's [Virtualbox](https://www.virtualbox.org/wiki/Downloads) are used for integration testing.

A working ChefDK installation set as your system's default ruby. ChefDK can be downloaded at <https://downloads.chef.io/chef-dk/>.

## Run tests

Use [`kitchen`](https://kitchen.ci/) to run the tests. For example:

```bash
$ kitchen create default-centos-7
$ kitchen converge default-centos-7
$ kitchen verify default-centos-7
```

For full documentation on the Kitchen please visit official website at <https://kitchen.ci/>.