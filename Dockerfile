FROM ubuntu:14.04
MAINTAINER MikaXII <mika@recalbox.com>

ENV DOKUWIKI_VERSION  2016-06-26a
ENV DOKUWIKI_CHECKSUM 9b9ad79421a1bdad9c133e859140f3f2
ENV PANDOC_VERSION 1.17.0.2
ENV LIBGMP10_VERSION 6.0.0
ENV SOURCE /tmp/recalbox-os.wiki
ENV DEST /dokuwiki/data/pages
ENV LOG  /migration.log
ENV ERR /migration.err
ENV MEDIA /dokuwiki/data/media
ENV WIKI_SOURCE https://github.com/recalbox/recalbox-os.wiki.git

ADD dokuwiki.sh /usr/local/bin/dokuwiki

#RUN apk --no-cache add curl lighttpd php5-cgi php5-curl php5-gd php5-json php5-openssl php5-xml php5-zlib bash git dpkg ca-certificates \
#    && curl -Lo dokuwiki.tgz http://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz \
#    && echo $DOKUWIKI_CHECKSUM "" dokuwiki*.tgz | sha256sum -c - \
#    && tar zxf dokuwiki*.tgz \
#    && rm dokuwiki*.tgz \
#    && mv dokuwiki* dokuwiki \
#    && chmod 755 dokuwiki \
#    && chmod +x /usr/local/bin/dokuwiki \
#    && sed -ie "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/php.ini

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install wget git curl lighttpd php5-cgi php5-gd php5-ldap && \
    apt-get clean autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

RUN curl -Lo /dokuwiki.tgz "http://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz" && \
    if [ "$DOKUWIKI_CHECKSUM" != "$(md5sum /dokuwiki.tgz | awk '{print($1)}')" ];then echo "Wrong md5sum of downloaded file!"; exit 1; fi && \
    mkdir /dokuwiki && \
    tar -zxf dokuwiki.tgz -C /dokuwiki --strip-components 1 && \
    rm dokuwiki.tgz

# Pandoc + deb
# http://ftp.fr.debian.org/debian/pool/main/g/gmp/libgmp10_$LIBGMP10_VERSION+dfsg-6_amd64.deb -O libgmp10.deb
# https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-amd64.deb -O pandoc.deb
#RUN wget https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-amd64.deb -O pandoc.deb
#RUN wget http://ftp.fr.debian.org/debian/pool/main/g/gmp/libgmp10_$LIBGMP10_VERSION+dfsg-6_amd64.deb -O libgmp10.deb
RUN curl -Lo pandoc.deb https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-amd64.deb
RUN curl -Lo libgmp10.deb http://ftp.fr.debian.org/debian/pool/main/g/gmp/libgmp10_$LIBGMP10_VERSION+dfsg-6_amd64.deb
#RUN dpkg --clear-avail
RUN dpkg -i libgmp10.deb && rm libgmp10.deb
RUN dpkg -i pandoc.deb && rm pandoc.deb


# Set up ownership
RUN chown -R www-data:www-data /dokuwiki

# Configure lighttpd
ADD dokuwiki.conf /etc/lighttpd/conf-available/20-dokuwiki.conf
RUN lighty-enable-mod dokuwiki fastcgi accesslog
RUN mkdir /var/run/lighttpd && chown www-data.www-data /var/run/lighttpd


EXPOSE 80
VOLUME ["/dokuwiki/data/","/dokuwiki/lib/plugins/","/dokuwiki/conf/","/dokuwiki/lib/tpl/","/var/log/"]

# Add migration here with import true/false
ADD migration.sh /usr/local/bin/migration.sh
# RUN migration.sh

RUN chmod + x /usr/local/bin/dokuwiki
ENTRYPOINT ["/usr/local/bin/dokuwiki"]




#ADD lighttpd.conf /etc/lighttpd/lighttpd.conf

#VOLUME ["/dokuwiki/data", "/dokuwiki/lib/plugins", \
#        "/dokuwiki/conf", "/dokuwiki/lib/tpl"]

#EXPOSE 80

#ENTRYPOINT ["dokuwiki"]
