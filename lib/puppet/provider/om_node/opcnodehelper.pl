#!/opt/OV/nonOV/perl/a/bin/perl

# short perl script to extract node information from
# the node database.
#
# The script is used by the opcnode provider because the
# command line tools provided by HP are not able to query
# all node information.
# Example: It is not possible to get all layoutgroups a
# specific node is assigned to.
#
# The script does not query the database directly but
# uses the OVO API. The OVO API comes as a separate
# package and additional steps may be necessary to
# install the perl interface.
#
# Installation instructions may be found at
# http://www.blue-elephant-systems.com/component/task,doc_download/gid,118/Itemid,141/
#
# YOU HAVE TO CHANGE THE adm_p variable IF YOU DO
# NOT USE THE DEFAULT PASSWORD

use strict;
use warnings;

# library for the perl OVO API
use OV::OVO::Server;

# user and password to connect against node db. You may have to change these.
# If you just know the clear text password you can obtain the crypted value with
# a simple script that does just this
# print OV::OVO::Server::OVConnection::encryptPasswd('clear_text_pw')."\n";
my $adm_u = 'opc_adm';
my $adm_p = '62f6f26c38a92d3a';

# a shared connection is used implicitly in all following API calls
my $conn = new OV::OVO::Server::OVSharedConnection($adm_u, $adm_p, undef);

# this hashref stores all node information. Hashkey is the nodename (most
# likely the fqdn of the node). The value is a hashref with the keys label,
# ipaddress etc that describes the node
my $nodes;

# the OVO API returns integer values for node type, communication type and
# and machine type but opcnode operates with strings. So we need a proper
# translation. Translation table is provided with different hashes.
my %trans_node_type = (
  $OV::OVO::Serverc::OPC_NODE_DISABLED        => 'DISABLED',
  $OV::OVO::Serverc::OPC_NODE_CONTROLLED      => 'CONTROLLED',
  $OV::OVO::Serverc::OPC_NODE_MONITORED       => 'MONITORED',
  $OV::OVO::Serverc::OPC_NODE_MESSAGE_ALLOWED => 'MESSAGE_ALLOWED',
);
my %trans_communication_type = (
  $OV::OVO::Serverc::OPC_COMM_UNSPEC_COMM  => 'COMM_UNSPEC_COMM',
  $OV::OVO::Serverc::OPC_COMM_BBC          => 'COMM_BBC',
);
my %trans_machine_type = (
  $OV::OVO::Serverc::OPC_MACHINE_OTHER             => 'MACH_BBC_OTHER_IP',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_SOL10_X86     => 'MACH_BBC_SOL10_X86',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_SOL_SPARC     => 'MACH_BBC_SOL_SPARC',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_LX26RPM_IPF64 => 'MACH_BBC_LX26RPM_IPF64',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_LX26RPM_X86   => 'MACH_BBC_LX26RPM_X86',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_LX26RPM_X64   => 'MACH_BBC_LX26RPM_X64',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_WINXP_IPF64   => 'MACH_BBC_WINXP_IPF64',
  $OV::OVO::Serverc::OPC_MACHINE_NON_IP            => 'MACH_BBC_OTHER_NON_IP',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_HPUX_IPF32    => 'MACH_BBC_HPUX_IPF32',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_HPUX_PARISC   => 'MACH_BBC_HPUX_PA_RISC',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_AIX_PPC       => 'MACH_BBC_AIX_PPC',
  $OV::OVO::Serverc::OPC_MACHINE_BBC_WINNT_X64     => 'MACH_BBC_WIN2K3_X64', # oh dear ;-)
  $OV::OVO::Serverc::OPC_MACHINE_BBC_WINNT_X86     => 'MACH_BBC_WINNT_X86',
);
my %trans_network_type = (
  $OV::OVO::Serverc::OPC_NETWORK_NO_NODE      => 'NETWORK_NO_NODE',
  $OV::OVO::Serverc::OPC_NETWORK_IP           => 'NETWORK_IP',
  $OV::OVO::Serverc::OPC_NETWORK_OTHER        => 'NETWORK_OTHER',
  $OV::OVO::Serverc::OPC_NETWORK_UNKNOWN      => 'NETWORK_UNKNOWN',
  $OV::OVO::Serverc::OPC_NODE_PATTERN_IP_ADDR => 'PATTERN_IP_ADDR',
  $OV::OVO::Serverc::OPC_NODE_PATTERN_IP_NAME => 'PATTERN_IP_NAME',
  $OV::OVO::Serverc::OPC_NODE_PATTERN_OTHER   => 'PATTERN_OTHER',
);


# This is called by main. Returns all nodes with all information
# as a hash reference
sub getAllNodes() {
  my $nodes = {};

  my $all_nodes = new OV::OVO::Server::OVNodeList();
  OV::OVO::Server::OVNode::getList($all_nodes);

  # iterate over all nodes and gather all information that is
  # stored at node level
  for(my $i = 0; $i < $all_nodes->getNumElements(); $i++) {
    my $node = $all_nodes->getElement($i);
    my $name = $node->getName();

    $node->get();
    $nodes->{$name} = {};
    $nodes->{$name}->{'label'} = $node->getLabel();
    $nodes->{$name}->{'ipaddress'} = $node->getIPAddress();
    $nodes->{$name}->{'communication_type'} = $node->getCommType();
    $nodes->{$name}->{'node_type'} = $node->getControl();
    $nodes->{$name}->{'machine_type'} = $node->getMachineType();
    $nodes->{$name}->{'network_type'} = $node->getNetworkType();
    if ($node->getIPFlags & $OV::OVO::Serverc::OPC_IP_STATIC) {
      $nodes->{$name}->{'dynamic_ip'} = 'no'
    }
    else {
      $nodes->{$name}->{'dynamic_ip'} = 'yes'
    }
    $nodes->{$name}->{'node_groups'} = [];
    $nodes->{$name}->{'layout_groups'} = [];
  }

  # next step: add node group assignments to our nodes
  addNodeGroups($nodes);

  # next step: add layout group assignments to our nodes
  addLayoutGroups($nodes);

  return $nodes;
}

# To add node group information to nodes we have to iterate over
# each nodegroup. For each nodegroup we retrieve the assigned
# groups and update our node hash
sub addNodeGroups {
  my $nodes = shift;

  my $all_nodegroups = new OV::OVO::Server::OVNodeGroupList();
  OV::OVO::Server::OVNodeGroup::getList($all_nodegroups);

  for(my $i = 0; $i < $all_nodegroups->getNumElements(); $i++) {
    my $nodegroup = $all_nodegroups->getElement($i);
    my $name = $nodegroup->getName;

    my $assigned_nodes = new OV::OVO::Server::OVNodeList();
    $nodegroup->getNodes($assigned_nodes);

    for (my $j = 0; $j < $assigned_nodes->getNumElements; $j++) {
      my $nodename = $assigned_nodes->getElement($j)->getName;
      if(exists $nodes->{$nodename}) {
        push @{$nodes->{$nodename}->{'node_groups'}}, $name;
      }
      else {
        die "Node $nodename is assigned to nodegroup $name but was not found in node hash\n";
      }
    }
  }
}

# sub walkLayoutGroup
# this method takes a hashref of all nodes, a layoutgroup object and
# the path to the layoutgroup. The function is first called with a
# layoutgroup at the hierarchy level and a path of /<HIERARCHY>.
# All nodes that are directly assigned to the specified layoutgroup will
# be updated with a layout_group element of /<HIERACHY>/<LAYOUTGROUP>
# The next step is to call the same function recursivly on all child
# layoutgroups with a modified path of /<HIERARCHY>/<LAYOUTGROUP>.
# If a node is assigned to such a child layoutgroup it will be updated with
# /<HIERARCHY>/<LAYOUTGROUP>/<CHILD_LAYOUTGROUP> etc.
sub walkLayoutGroup {
  my $nodes = shift;
  my $currentpath = shift;
  my $layoutgroup = shift;

  my $name = $layoutgroup->getName();

  # update all directly assigned nodes
  my $assigned_nodes = new OV::OVO::Server::OVNodeList();
  $layoutgroup->getNodes($assigned_nodes);

  for(my $i = 0; $i < $assigned_nodes->getNumElements(); $i++) {
    my $nodename = $assigned_nodes->getElement($i)->getName;
    if(exists($nodes->{$nodename})) {
      push @{$nodes->{$nodename}->{'layout_groups'}}, "${currentpath}/${name}";
    }
    else {
      die "Node $nodename is assigned to layoutgroup $name but was not found in node hash\n";
    }
  }

  # now recursivly check all sub layoutgroups
  my $assigned_layoutgroups = new OV::OVO::Server::OVLayoutGroupList();
  $layoutgroup->getLayoutGroups($assigned_layoutgroups);

  for(my $i = 0; $i < $assigned_layoutgroups->getNumElements(); $i++) {
    my $layoutgroup = $assigned_layoutgroups->getElement($i);
    walkLayoutGroup($nodes, "${currentpath}/${name}", $layoutgroup);
  }
}


# to add layout group information to our nodes we first have to
# get a list of node hierarchies. We then iterate over the different
# hierarchies and get nodes that are assigned to the top level
# hierarchies. For each hierarchy we get a list of all assigned
# layoutgroups and recursivly follow all possible child layoutgroup
sub addLayoutGroups {
  my $nodes = shift;

  my $all_hierarchies = new OV::OVO::Server::OVNodeHierarchyList();
  OV::OVO::Server::OVNodeHierarchy::getList($all_hierarchies);

  for (my $i = 0; $i < $all_hierarchies->getNumElements(); $i++) {
    my $hierarchy = $all_hierarchies->getElement($i);
    my $name = $hierarchy->getName();

    # update all directly assigned nodes
    my $assigned_nodes = new OV::OVO::Server::OVNodeList();
    $hierarchy->getNodes($assigned_nodes);

    for(my $j = 0; $j < $assigned_nodes->getNumElements(); $j++) {
      my $nodename = $assigned_nodes->getElement($j)->getName;
      if(exists $nodes->{$nodename}) {
        push @{$nodes->{$nodename}->{'layout_groups'}}, "/${name}";
      }
      else {
        die "Node $nodename is assigned to hierarchy $name but was not found in node hash\n";
      }
    }

    # recursivly check all assigned layout groups and update found nodes
    my $assigned_layoutgroups = new OV::OVO::Server::OVLayoutGroupList();
    $hierarchy->getLayoutGroups($assigned_layoutgroups);

    for(my $j = 0; $j < $assigned_layoutgroups->getNumElements(); $j++) {
      walkLayoutGroup($nodes,"/${name}",$assigned_layoutgroups->getElement($j));
    }
  }
}

# the API will retrieve keys for certain properties but we want to
# have nice descriptive strings. The translate method takes a
# hashref that works as a translation table and the input value
# we want to look up in the table
sub translate {
  my $trans_table = shift;
  my $input = shift;

  if (!$trans_table) {
    return $input;
  }
  elsif (exists $trans_table->{$input}) {
    return $trans_table->{$input};
  }
  else {
    return;
  }
}

sub main {
  eval {
    $nodes = getAllNodes();
    1;
  } or do {
    print "Exception while getting node information: ", $@, "\n";
    exit 1;
  };

  my $format      = (" " x 8)."%-18s : %s\n";
  my $list_format = (" " x 26)."   %s\n";

  # Getting nodeinformation worked. Yeah! Let's print everything and sort it
  # sorting is not needed
  foreach my $name (sort keys %{$nodes}) {
    $node = $nodes->{$name};

    print "${name}\n";

    foreach my $property ('label','ipaddress','dynamic_ip','communication_type','node_type','machine_type','network_type') {
      if (exists $node->{$property}) {
        my $value = $node->{$property};
        my $t = undef;
        $t = \%trans_communication_type if $property eq 'communication_type';
        $t = \%trans_node_type          if $property eq 'node_type';
        $t = \%trans_machine_type       if $property eq 'machine_type';
        $t = \%trans_network_type       if $property eq 'network_type';
        if (my $tvalue = translate($t, $value)) {
          printf($format,$property,$tvalue);
        }
        else {
          die "Node $name property $property with value $value could not be translated to a string";
        }
      }
      else {
        die "Somehow, $property of node $name is not set\n";
      }
    }

    foreach my $listproperty ('node_groups','layout_groups') {
      if (exists $node->{$listproperty}) {
        if (my $first_element = pop @{$node->{$listproperty}}) {
          printf($format,$listproperty,$first_element);
          foreach my $other_element (@{$node->{$listproperty}}) {
            printf($list_format,$other_element);
          }
        }
        else {
          printf($format,$listproperty,'(none)');
        }
      }
      else {
        die "Somehow, $listproperty of node $name is not set\n";
      }
    }

  }
  exit 0;
}

&main;
