Role Name
=========

ansible-jails is a FreeBSD-specific jails management tool, targeted
specifically for immutable jail management, based off poudriere images,
with permanent data held in zfs datasets.

In most deployments there will be load balancers that provide continuous
service availability, even if a given jail is temporarily down for
upgrades and maintenance.

There are two main modes for this role:

- a constrained deployment, where immutable jail templates are built
    via [`poudriere-image(8)`](https://man.freebsd.org/poudriere-image)
    with `-t tar` option, and jails do not need any external access
- a permissive deployment, where jails can access pkg.FreeBSD.org directly

If you build a custom image, make sure you have these packages included:

    - lang/python3
    - ports-mgmt/pkg

The minimal image required is simply the standard FreeBSD `base.txz`
tarball, for your appropriate release and architecture.

See Usage section below for jail layout and general tips.

Requirements
------------

- zfs-enabled FreeBSD on target machines
- sshjail plugin for managing remote jails (included)

Role Variables
--------------

Refer to the example playbook for details.

Dependencies
------------

n/a

Example Playbook
----------------

```yaml
---
# prepare jail templates, and register in ansible
- hosts: just_servers
  become: yes
  roles:
   - jails # apply this role

  vars:
    # mandatory
    # the destination zpool to hold jails, downloads, templates, and jails
    jails_zpool: ocean

    # optional, self-explanatory
    jails_mount: '/jails'

    # URL to fetch from, either FreeBSD base or a poudriere-image(8) tarball
    # self-built images should contain lang/python3 /usr/local/bin/python3
    # for ansible to work
    jails_url: 'https://example.org/poudriere/images/1999-01-01.txz'

    # system-wide jail.conf settings, see templates/ dir for default
    jails_jail_conf: 'jail.conf.j2'

    # Only the URL actually needs to be overridden but all can be customised.
    # Leaving all settings blank will fetch the official FreeBSD tarball,
    # matching the architecture of the destination jail host.
    jails_site: 'https://download.freebsd.org/ftp/releases/'
    jails_arch: '{{ "aarch64" if ansible_machine == "arm64" else ansible_machine }}'
    jails_target: '{{ ansible_distribution_release }}'
    jails_tarball: 'base.txz'
    jails_tarball_sha256: 'abc123cafedeadb33f' # used if provided
    # these are combined by default into an architecture-dependent path
    # jails_url: '{{ [jails_site, jails_arch, jails_target, jails_tarball] | join("/") }}'

    # resolv.conf for use within jail
    jails_resolv_conf: |
      nameserver 9.9.9.9
      search example.org

    jails_repo: 'FreeBSD' # or choose your custom package repo
    # ABI if you wish to enforce an ABI less than that of the host machine
    # by default the architecture is auto-detected as amd64 | aarch64
    jails_abi:  'FreeBSD:13:aarch64'
    # overridable per jail with `packages: ...`
    jails_default_packages:
        - lang/python3
        - sysutils/spiped
    # a list of jails to create, or just a variable from inventory or vars
    # if undefined, no jails will be created, only templates
    jails_list:
    # a rose by any other name would smell as sweet
    - name: espresso
      log: /var/log/jail_espresso.log
    # use a specific interface, ip, and subnet
    - name: ristretto
      ip4_addr: vtnet1|10.0.0.1/30
    # provide a custom jail.conf template
    - name: oatmilk
      hostname: oatmilk.example.org
      jail_conf: template.j2
    # too lazy to do a custom template but a few options would be nice
    - name: soy_latte
      tunables: |
        # read jail(8) for more useful settings
        allow.maximum.damage;
        permit.mayhem;
    # bind a zfs dataset into the jail
    # the dataset must exist, with properties jailed=on and mountpoint set
    - name: full_cream
      zfs: zpool/awesome/dataset
    # to use a different ABI for packages
    - name: minimal
      abi: FreeBSD:12:amd64
    # with extra packages
    - name: flat_white
      packages:
        - ftp/curl
    # enable daemons in rc.conf - none is started by default
    - name: daemonic
      daemons:
        - cron
        - sshd
        - syslogd

    # your ansible role to be applied to the templated jail prior to final snapshot
    jails_template_role: 'my_template_role'

# do jail things to your new jails after provisioning
- hosts: just_jails
  become: yes
  roles:
   - example_role

```

Usage
-----

Your jails have a standard `/etc/jail.conf.d/<name>.conf` file, and
will start and stop using the standard FreeBSD `jail` service:

```shell
# service jail start monkey
# service jail console monkey
# service jail stop monkey
```

Enter the jail via either `service jail console <name>` for a full
shell, or use the quick `jexec <name> ...`.

After deployment, you will have the following directory / dataset layout:

- /etc/rc.conf.d/jail       - enables the standard FreeBSD jail service
- /etc/jail.conf            - default jail.conf settings
- /etc/jail.conf.d/<name>   - per-jail jail.conf settings
- /jails                                                    [dataset]
- /jails/downloads/<tag>-<machine>-<architecture>           [dataset]
- /jails/templates/<tag>-<machine>-<architecture>           [dataset]
- /jails/instances/<tag>-<machine>-<architecture>/<name>    [dataset]

The latter is your jail, cloned from the prior template. This layout
permits to have multiple generations of a given name present, to
simplify upgrades and deployments.

If you provide a per-jail zfs dataset, it will be mounted at the
appropriate place in your jail's filesystem tree. `jailed: on`
must be set at creation time, to avoid polluting the host system.

It is highly recommended, that permanent datasets live outside
the immutable jail images, so that ephemeral jail content can be
managed separately from critical jailed data:

```yaml
- name: create future jailed zfs dataset for awesome DB
  zfs:
    name: zroot/jailed/awesome-db
    state: present
    extra_zfs_properties:
      compression:        "zstd"
      jailed:             "on"
      checksum:           "skein"
      logbias:            "throughput"
      mountpoint:         "/var/db/awesome"
      primarycache:       "metadata"
      readonly:           "off"
      recordsize:         "16k"
      redundant_metadata: "most"
```

If this dataset is set with `canmount: off`, you can create child
datasets that can mounted at arbitrary locations within the jail.

License
-------

BSD-2-Clause

Author Information
------------------

See https://skunkwerks.at/ for contact details.
