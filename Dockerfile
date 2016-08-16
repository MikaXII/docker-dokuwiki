FROM alpine:3.4
MAINTAINER MikaXII <mika@recalbox.com>

ENV DOKUWIKI_VERSION  2016-06-26a
ENV DOKUWIKI_CHECKSUM dfdb243cc766482eeefd99e70215b289c9aa0bd8bee83068f438440d7b1a1ce6
ENV PANDOC_VERSION 1.17.0.2
ENV LIBGMP10_VERSION 6.0.0
ENV SOURCE /tmp/recalbox-os.wiki
ENV DEST /dokuwiki/data/pages
ENV LOG  /migration.log
ENV ERR /migration.err
ENV MEDIA /dokuwiki/data/media
ENV WIKI_SOURCE https://github.com/recalbox/recalbox-os.wiki.git

ADD dokuwiki.sh /usr/local/bin/dokuwiki

RUN apk --no-cache add curl lighttpd php5-cgi php5-curl php5-gd php5-json php5-openssl php5-xml php5-zlib bash git dpkg ca-certificates \
    && curl -Lo dokuwiki.tgz http://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz \
    && echo $DOKUWIKI_CHECKSUM "" dokuwiki*.tgz | sha256sum -c - \
    && tar zxf dokuwiki*.tgz \
    && rm dokuwiki*.tgz \
    && mv dokuwiki* dokuwiki \
    && chmod 755 dokuwiki \
    && chmod +x /usr/local/bin/dokuwiki \
    && sed -ie "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/php.ini

# Pandoc + deb
# http://ftp.fr.debian.org/debian/pool/main/g/gmp/libgmp10_$LIBGMP10_VERSION+dfsg-6_amd64.deb -O libgmp10.deb
# https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-amd64.deb -O pandoc.deb
RUN wget https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-amd64.deb -O pandoc.deb
RUN wget http://ftp.fr.debian.org/debian/pool/main/g/gmp/libgmp10_$LIBGMP10_VERSION+dfsg-6_amd64.deb -O libgmp10.deb
RUN dpkg -i libgmp10.deb && rm libgmp10.deb
RUN dpkg -i pandoc.deb && rm pandoc.deb

# Add migration here with import true/false
ADD migration.sh /usr/local/bin/migration.sh
RUN migration.sh

ADD lighttpd.conf /etc/lighttpd/lighttpd.conf

VOLUME ["/dokuwiki/data", "/dokuwiki/lib/plugins", \
        "/dokuwiki/conf", "/dokuwiki/lib/tpl"]

EXPOSE 80

ENTRYPOINT ["dokuwiki"]
