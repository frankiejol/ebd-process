package eBD::Process;

use strict;
use warnings;
use vars qw( @ISA @EXPORT);


use DBI;
use XML::Simple;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(open_log open_dbh print_log log_env);

# ABSTRACT: Common eBD process functions

our $VERSION = '0.0.1';

=head1 NAME

eBD::Process -  Common eBD process functions

=head1 VERSION

version 0.0.1

=cut

=head1 SYNOPSYS

  use eBD::Process;

  my $dbh = open_dbh();

=cut

=head1 METHODS

=head2 open_dbh

Opens the DBH of the current eBD running. As it runs inside eBD, it finds the
alias in the environment variable EBD_ALIAS.

=head3 returns

The dbh

=head3 example

  my $dbh = open_dbh();

=cut

=head1 INSTALLATION

=head2 Operating System Perl

If you are able to run a shell in your system. Install the library doing

  $ perl Makefile.PL
  $ make test
  $ sudo make install

=head2 eBD perl

If you want to run this process from eBD perl. You have to find out where
it is, maybe something like ~ebdfas/system/bin/perl

  # ~ebdas/system/bin/perl Makefile.PL
  # make test
  # make install
 
Now the script must run with eBD perl. One not bad way is running it from
a shell:

   #!/bin/bash
   CMD=$EBD_SYSTEM/bin/perl
   FILENAME=`basename $0 .sh`
   exec $CMD $FILENAME.pl $@

This may raise a security problem because bogus arguments can be passed to
this shell and run by the eBD user. Also most of the eBD perl libraries are
quite old and should not be upgraded. If you need to use some library you
should install it in the OS perl, not the eBD perl.


=head2 No way to install it

Upload the .pm file  and call it from your script like this:

  use lib '.';
  use eBD::Process;

=cut

my $FILE_LOG = $0;
$FILE_LOG =~ s{.*/}{};
$FILE_LOG = "/var/tmp/$FILE_LOG.log";

my $EBD_BASE = $ENV{EBD_BASE}    or die "Missing ENV: EBDUSER\n";
my $EBD_ALIAS= $ENV{EBD_ALIAS}  or die "Missing ENV: EBD_ALIAS\n";
my %DRIVER_LC =  map { $_ => 1} qw ( mysql );
my $LOG;
my $DBH;

sub print_log {
    open_log() if !$LOG;
    my $now = localtime(time);
    print $LOG "$now ".join(" ",@_)."\n";
}

sub open_log {
    open $LOG,'>>',$FILE_LOG or die "$! $FILE_LOG";
    print_log("START");
}

sub _dump {
    my $data    = shift;

    my $ret = '';
    for (sort keys %$data) {
        $ret .= ", "                if $ret;
        $ret .= "$_=$data->{$_}";
    }
    return $ret;
}

sub _connect_dbh {
    my $connection = shift;

    my $db = $connection->{Database}    or die "Missing database in "._dump($connection);
    my $host = $connection->{Hostname};
    $host = 'localhost' if !$host or ref($host); # ref vol dir que és llista buida aquí

    my $user = $connection->{Username}  or die "Missing Username in "._dump($connection);

    my $pass = ($connection->{Password} or '');
    my $drv  = ( $connection->{Driver}  or 'mysql');
    $drv = lc($drv) if $DRIVER_LC{lc($drv)};

    my $port = ( $connection->{Port}    or 3306 );

    my $dbh_cat= DBI->connect("dbi:$drv:database=$db;host=$host;port=$port", $user, $pass
            ,{RaiseError => 1, PrintError => 1});
    my $sth = $dbh_cat->prepare(
        "SELECT base_datos, driver, ip, port, username, password "
        ." FROM Drivers d,Servidores s "
        ." WHERE s.idDriver = d.idDriver "
        ."  AND tipo='SQL' "
        ."  AND base_datos like ?");
    $sth->execute("EBD$EBD_ALIAS%");
    my ($db2,$drv2,$host2,$port2,$user2,$pass2) = $sth->fetchrow;
    $sth->finish;
    die "Missing db like $EBD_ALIAS\% at table Servidores at $db\n"
        if !$db2;
    $drv2 = lc($drv2) if $DRIVER_LC{lc($drv2)};
    $port2 = $port if !$port2;
    $DBH = DBI->connect("dbi:$drv2:database=$db2;host=$host2;port=$port2", $user2, $pass2
            ,{RaiseError => 1, PrintError => 1});
    return $DBH;
}

sub open_dbh {
    my $file_config = $EBD_BASE."/app/conf/ebd.xml";
    die "Missing $file_config" if ! -e $file_config;
    my $config = XMLin($file_config);
#    print Dumper($config);
    for my $ebd (sort keys %$config) {
        my $alias = $config->{$ebd}->{Alias};
        next if !defined $alias || $alias ne $ENV{EBD_ALIAS};
        return _connect_dbh($config->{$ebd}->{CatalogDB});
    }
}

sub log_env {
    for (sort keys %ENV) {
        print_log("$_ : $ENV{$_}");
    }
}

sub _close_log {
    return if !$LOG;
    print_log("END");
    close $LOG;
}

END {
    _close_log();
}

1;
