use Test::More;

use strict;
use warnings;

use Cwd;

sub init_config {
    mkdir "ebd"       if ! -d "ebd";
    mkdir "ebd/app";
    mkdir "ebd/app/conf";
    my $file_config = $ENV{EBD_BASE}."/app/conf/ebd.xml";
    open my $config,'>',$file_config or die "$! $file_config";
print $config <<'EOF';
<config>

<!--BEGIN test-->
<eBD Alias="test">
        <Home>/</Home>
        <ComponentRoot>/home/ebdas/app/components/</ComponentRoot>
        <UserRoot>/home/ebdas/userdata/test/</UserRoot>
        <ServersPath>/home/ebdas/system/bin/</ServersPath>
        <CatalogDB>
                <Database>eBDtest</Database>
                <Hostname>localhost</Hostname>
                <Username>test</Username>
                <Password>hola</Password>
                <Driver>MySQL</Driver>
                <ProxyHost>localhost</ProxyHost>
                <ProxyPort>2345</ProxyPort>
        </CatalogDB>
        <DebugLevel>0</DebugLevel>
        <SOAPHandler>On</SOAPHandler>
    <ExecAllowed>On</ExecAllowed>
</eBD>
<!--END test-->
</config>
EOF
    close $config;
}

$ENV{EBD_BASE} = getcwd()."/ebd";
$ENV{EBD_ALIAS}='test';
use_ok('eBD::Process');

init_config();

my $dbh = open_dbh();
ok($dbh);
ok(ref $dbh);
done_testing();
