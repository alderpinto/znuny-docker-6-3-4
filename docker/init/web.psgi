use Plack::App::CGIBin;
use Plack::Builder;
use HTTP::Server::PSGI;
use Plack::App::File;
use lib "/opt/znuny";
use lib "/opt/znuny/Kernel/cpan-lib";

my $app = Plack::App::CGIBin->new(
    root => "/opt/znuny/bin/cgi-bin",
    exec_cb => sub { 1 }
    )->to_app;
my $app_web = Plack::App::File->new(root => "/opt/znuny/var/httpd/htdocs")->to_app;
builder {
      enable "StackTrace", force => $ENV{DEBUG_MODE};
      mount "/znuny" => $app;
      mount "/znuny-web" => $app_web;
};