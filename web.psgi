use Plack::App::CGIBin;
use Plack::Builder;
use HTTP::Server::PSGI;
use Plack::App::File;
use lib "/opt/otrs";
use lib "/opt/otrs/Kernel/cpan-lib";

my $app = Plack::App::CGIBin->new(
    root => "/opt/otrs/bin/cgi-bin",
    exec_cb => sub { 1 }
    )->to_app;
my $app_web = Plack::App::File->new(root => "/opt/otrs/var/httpd/htdocs")->to_app;
builder {
      enable "StackTrace", force => $ENV{DEBUG_MODE};
      mount "/otrs" => $app;
      mount "/otrs-web" => $app_web;
};