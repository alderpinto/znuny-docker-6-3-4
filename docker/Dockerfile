FROM nginx:1.23.4-alpine3.17-perl
LABEL maintainer="Alder Pinto <alder.pinto@gmail.com>"
ENV ZNUNY_VERSION=6.3.4
ENV ZNUNY_VERSION_ITSM=6.3.3
ENV ZNUNY_VERSION_PRIMARYSECONDARY=6.3.2
ENV ZNUNY_VERSION_SURVEY=6.3.1
ENV ZNUNY_VERSION_FAQ=6.3.2
ENV ZNUNY_VERSION_CLONEDB=6.3.1

ENV ZNUNY_ROOT="/opt/otrs"

#WORKDIR /opt

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
perl-encode-hanextra perl-data-optlist perl-io-gzip perl-pathtools perl-scalar-list-utils && \
cpanm CGI::Compile Plack::Middleware::Expires Plack::Middleware::Session::Cookie Captcha::reCAPTCHA

RUN wget https://download.znuny.org/releases/znuny-${ZNUNY_VERSION}.tar.gz && \
#mkdir ${ZNUNY_ROOT} && \
tar xfz znuny-${ZNUNY_VERSION}.tar.gz -C /opt && \
mv /opt/znuny-${ZNUNY_VERSION} ${ZNUNY_ROOT} && \
mkdir ${ZNUNY_ROOT}/addons && \
wget https://download.znuny.org/releases/itsm/bundle6x/ITSM-${ZNUNY_VERSION_ITSM}.opm -P ${ZNUNY_ROOT}/addons/ && \
wget https://download.znuny.org/releases/packages/OTRSMasterSlave-${ZNUNY_VERSION_PRIMARYSECONDARY}.opm -P ${ZNUNY_ROOT}/addons/ && \
#wget https://download.znuny.org/releases/packages/Znuny-PrimarySecondary-${ZNUNY_VERSION_PRIMARYSECONDARY}.opm -P ${ZNUNY_ROOT}/addons/ && \
wget https://download.znuny.org/releases/packages/Survey-${ZNUNY_VERSION_SURVEY}.opm -P ${ZNUNY_ROOT}/addons/ && \
wget https://download.znuny.org/releases/packages/FAQ-${ZNUNY_VERSION_FAQ}.opm -P ${ZNUNY_ROOT}/addons/ && \
wget https://download.znuny.org/releases/packages/OTRSCloneDB-${ZNUNY_VERSION_CLONEDB}.opm -P ${ZNUNY_ROOT}/addons/ 

RUN adduser -h ${ZNUNY_ROOT} -G nginx -s /bin/sh -H -D otrs && \
${ZNUNY_ROOT}/bin/otrs.SetPermissions.pl --otrs-user=otrs --web-group=nginx && \
echo "*/5 * * * * /opt/otrs/bin/otrs.Daemon.pl start >> /dev/null" >> /var/spool/cron/crontabs/otrs && \
touch ${ZNUNY_ROOT}/var/tmp/firsttime && \
cp -prf ${ZNUNY_ROOT}/Kernel/Config.pm.dist ${ZNUNY_ROOT}/Kernel/Config.pm

#Supervisord configuration
COPY supervisord.conf /etc/

# Add scripts and function files
COPY *.sh /

# Remove packages we won't need at runtime
RUN apk del make gcc build-base gnupg perl perl-dev perl-app-cpanminus

RUN rm /var/cache/apk/* && \
# Remove CPAN cache
rm -rf /root/.cpanm

RUN mv ${ZNUNY_ROOT} / && \
rm -rf /opt/znuny-${ZNUNY_VERSION}.tar.gz && \
chmod 755 /*.sh

EXPOSE 8880 8881

CMD ["/run.sh"]
