Puppet ipmi Module
==================

Overview
--------

Manages BMC using ipmitool with optional [Foreman](https://theforeman.org/) integration. 

Description
-----------

Forked from [jhoblitt-ipmi](https://forge.puppet.com/jhoblitt/ipmi) with much thanks to the original author.  

- Installs the [OpemIPMI](http://openipmi.sourceforge.net/) package and service
- Provides IPMI LAN and user facts
- Adding/updating/disabling of IPMI users
- Purging users beyond those wanted
- Setting of IPMI LAN network settings
- LAN facts automatically will add/update BMC NIC interface in [Foreman](https://www.theforeman.org)
- User credentials from Foreman BMC interface can be applied to an IPMI user
    
Usage
-----

### Examples

```puppet 
include ipmi
```

Manage IPMI users:
```puppet
class { ipmi:
    purge_users => true,
    foreman_user => true,
    users => [
        {
            username => 'ADMIN',
            password => 'secret',            
        }, 
    ],    
}
```
