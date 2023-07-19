FROM nginx:1.23.4-alpine3.17-perl

WORKDIR /opt

# Note before you start:
# First build a tar of the source code: tar -czf build/angora-src.tar.gz --exclude build lib/perl services gui

# Add the alpine testing repository, for starman package
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Install apline packages for perl
RUN apk add bash tar make gcc build-base gnupg perl perl-dev perl-app-cpanminus 
RUN apk add --no-cache perl-plack perl-cgi-emulate-psgi perl-starman@testing supervisor postgresql15-client certbot certbot-nginx \
perl-datetime perl-dbi perl-archive-zip perl-authen-sasl perl-namespace-clean \
perl-moo perl-math-random-mt-auto perl-crypt-random perl-yaml-libyaml \
perl-xml-parser perl-xml-libxml perl-xml-libxslt perl-text-csv_xs perl-template-toolkit \
perl-spreadsheet-xlsx perl-ldap perl-net-dns perl-authen-ntlm perl-mail-imapclient \
perl-json-xs perl-data-uuid perl-datetime perl-date-format perl-crypt-jwt perl-crypt-openssl-x509 \
perl-css-minifier-xs perl-dbd-pg perl-dbd-mysql perl-dbd-odbc perl-javascript-minifier-xs \
perl-encode-hanextra perl-data-optlist perl-io-gzip perl-pathtools perl-scalar-list-utils&&\
cpanm CGI::Compile Plack::Middleware::Expires Plack::Middleware::Session::Cookie

RUN wget https://download.znuny.org/releases/znuny-7.0.7.tar.gz && \
tar xfz znuny-7.0.7.tar.gz && \
mv /opt/znuny-7.0.7 /opt/znuny

RUN adduser -h /opt/znuny -G nginx -s /bin/sh -H -D znuny&&\
/opt/znuny/bin/otrs.SetPermissions.pl --znuny-user=znuny --web-group=nginx &&\
echo "*/5 * * * * /opt/znuny/bin/znuny.Daemon.pl start >> /dev/null" >> /var/spool/cron/crontabs/otrs &&\
cp -prf /opt/znuny/Kernel/Config.pm.dist /opt/znuny/Kernel/Config.pm

ADD supervisord.conf /etc/

ADD run.sh /

# Remove packages we won't need at runtime
RUN apk del make gcc build-base gnupg perl perl-dev perl-app-cpanminus

RUN rm /var/cache/apk/* &&\
# Remove CPAN cache
rm -rf /root/.cpanm

RUN mkdir /app &&\
mkdir /app-files &&\
mv /opt/znuny /app-files/. &&\
rm -rf /opt/znuny-7.0.7.tar.gz &&\
chmod 755 /run.sh

EXPOSE 8880 8881

CMD ["/run.sh"]
