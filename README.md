Puppet Operations Manager Module
=================================

HP Operations Manager is a monitoring tool by Hewlett Packard. This repository
tries to provide puppet types and providers to ease the management of HP Operations
Manager nodes.

Installation
------------

Generally you need the following
* HP Operations Manager server should run on Unix and currently only OML9 is supported.
  While the types may run on older releases of OML have not been tested there.
* For the om\_node type to work you need the HP OVO API installed. You should be able to get
  the API for free if you already use HP OVO. You also have to install the perl bindings
  (you may find installation instructions in the links section). Make sure you can
  run the opcnodehelper.pl script inside the provider directory on the management server.
* To make use of the types copy this directory in your module's path. Make sure you have
  activated pluginsync in your agent's config.

Usage
-----

### om\_node type

The node type can be used to create a node that is assigned to specific node groups and is placed inside differen layout groups.
It does currently not handle direct policy assignments nor policy group assignments. It uses the `opcnode` command to create, delete
or modify a node but uses the `opcnodehelper.pl` script to read current node information from the OVO database. The provider does not
support changing a node's label (the provider will raise an error in case label is out of sync) because the `opcnode` command simply
does not have a command line argument for that task.

    om_node { 'testnode01.example.com':
      ensure             => present,
      label              => 'testnode01',
      ipaddress          => '10.0.0.1',
      network_type       => 'NETWORK_IP',
      machine_type       => 'MACH_BBC_LX26RPM_X64',
      communication_type => 'COMM_BBC',
      node_type          => 'CONTROLLED',
      dynamic_ip         => no,
      layout_groups      => [
        'Linux/Webserver',
        '/CustomHierarchy/physical/rz10',
      ],
      node_groups        => [
        'linux',
        'webserver',
        'basic',
      ],
    }

because the type makes use of some default values the above example can also be written as

    om_node { 'testnode01.example.com':
      ensure             => present,
      label              => 'testnode01',
      ipaddress          => '10.0.0.1',
      machine_type       => 'MACH_BBC_LX26RPM_X64',
      dynamic_ip         => no,
      layout_groups      => [
        'Linux/Webserver',
        '/CustomHierarchy/physical/rz10',
      ],
      node_groups        => [
        'linux',
        'webserver',
        'basic',
      ],
    }

Links
-----
* about the OVO API: http://www.blue-elephant-systems.com/content/view/294/314/
* installation instructions: http://www.blue-elephant-systems.com/component/option,com_docman/task,doc_download/gid,118/Itemid,141/
