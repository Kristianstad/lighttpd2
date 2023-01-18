# =========================================================================
# Init
# =========================================================================
# ARGs (can be passed to Build/Final) <BEGIN>
ARG SaM_REPO=${SaM_REPO:-ghcr.io/kristianstad/secure_and_minimal}
ARG ALPINE_VERSION=${ALPINE_VERSION:-3.17}
ARG IMAGETYPE="application"
ARG RUNDEPS="glib libev libbz2 libunwind"
ARG BUILDDEPS="libunwind-dev libidn-dev gnutls-dev libev-dev ragel zlib-dev openssl-dev mailcap glib-dev"
ARG CLONEGITS="https://git.lighttpd.net/lighttpd/lighttpd2.git"
ARG STARTUPEXECUTABLES="/usr/sbin/lighttpd2"
ARG BUILDCMDS=\
"cd lighttpd2 "\
"&& sed -i 's/set -e/set -ex/' autogen.sh "\
"&& sed -i 's/autoreconf --force --install/autoreconf --force --install --verbose --warnings=all/' autogen.sh "\
"&& ./autogen.sh "\
'&& eval "$COMMON_CONFIGURECMD --with-lua --with-openssl --with-kerberos5 --with-zlib --with-bzip2 --includedir=/usr/include/lighttpd2" '\
'&& eval "$COMMON_MAKECMDS" '\
'&& mv contrib/mimetypes.conf "$DESTDIR/" '\
'&& gzip "$DESTDIR/mimetypes.conf"'
ARG REMOVEDIRS="/usr/include"
# ARGs (can be passed to Build/Final) </END>

# Generic template (don't edit) <BEGIN>
FROM ${CONTENTIMAGE1:-scratch} as content1
FROM ${CONTENTIMAGE2:-scratch} as content2
FROM ${CONTENTIMAGE3:-scratch} as content3
FROM ${CONTENTIMAGE4:-scratch} as content4
FROM ${CONTENTIMAGE5:-scratch} as content5
FROM ${BASEIMAGE:-$SaM_REPO:base-$ALPINE_VERSION} as base
FROM ${INITIMAGE:-scratch} as init
# Generic template (don't edit) </END>

# =========================================================================
# Build
# =========================================================================
# Generic template (don't edit) <BEGIN>
FROM ${BUILDIMAGE:-$SaM_REPO:build-$ALPINE_VERSION} as build
FROM ${BASEIMAGE:-$SaM_REPO:base-$ALPINE_VERSION} as final
COPY --from=build /finalfs /
# Generic template (don't edit) </END>

# =========================================================================
# Final
# =========================================================================
ENV VAR_CONFIG_DIR="/etc/lighttpd2" \
    VAR_WWW_DIR="/var/www" \
    VAR_HTTP_SOCKET_FILE="/run/http/lighttpd.sock" \
    VAR_FASTCGI_SOCKET_FILE="/run/fastcgi/fastcgi.sock" \
    VAR_LINUX_USER="www-user" \
    VAR_FINAL_COMMAND="lighttpd2 -c '\$VAR_CONFIG_DIR/angel.conf'" \
    VAR_OPERATION_MODE="fcgi" \
    VAR_angel1_config="'\$VAR_CONFIG_DIR/lighttpd.conf'" \
    VAR_angel2_max_open_files="1024" \
    VAR_angel3_copy_env="[ 'PATH' ]" \
    VAR_angel4_max_core_file_size="0" \
    VAR_angel5_allow_listen="'0.0.0.0/0:8080'" \
    VAR_angel6_allow_listen="'unix:\$VAR_FASTCGI_SOCKET_FILE'" \
    VAR_setup1_module_load="[ 'mod_fastcgi' ]" \
    VAR_setup2_listen="'0.0.0.0:8080'" \
    VAR_setup3_workers="1" \
    VAR_setup4_io__timeout="120" \
    VAR_setup5_stat_cache__ttl="10" \
    VAR_setup6_tasklet_pool__threads="0" \
    VAR_mode_fcgi=\
"      docroot '\$VAR_WWW_DIR';\n"\
"      index [ 'index.php', 'index.html', 'index.htm', 'default.htm', 'index.lighttpd.html', '/index.php' ];\n"\
"      buffer_request_body false;\n"\
"      strict.post_content_length false;\n"\
"      if req.header['X-Forwarded-Proto'] =^ 'http' and req.header['X-Forwarded-Port'] =~ '[0-9]+' {\n"\
"         env.set 'REQUEST_URI' => '%{req.header[X-Forwarded-Proto]}://%{req.host}:%{req.header[X-Forwarded-Port]}%{req.raw_path}';\n"\
"      }\n"\
"     fastcgi 'unix:\$VAR_FASTCGI_SOCKET_FILE';\n"\
"     if request.is_handled { header.remove 'Content-Length'; }" \
    VAR_mode_normal=\
"      include '\$VAR_CONFIG_DIR/mimetypes.conf';\n"\
"      docroot '\$VAR_WWW_DIR';\n"\
"      index [ 'index.php', 'index.html', 'index.htm', 'default.htm', 'index.lighttpd.html', '/index.php' ];\n"\
"      static;\n"\
"      if request.is_handled {\n"\
"         if response.header['Content-Type'] =~ '^(.*/(javascript|json)|text/.*)(;|\$)' {\n"\
"            deflate;\n"\
"         }\\n"\
"      }" \
    VAR_mode_dual=\
"      include '\$VAR_CONFIG_DIR/mimetypes.conf';\n"\
"      docroot '\$VAR_WWW_DIR';\n"\
"      index [ 'index.php', 'index.html', 'index.htm', 'default.htm', 'index.lighttpd.html', '/index.php' ];\n"\
"      if phys.path =$ '.php' {\n"\
"         buffer_request_body false;\n"\
"         strict.post_content_length false;\n"\
"         if req.header['X-Forwarded-Proto'] =^ 'http' and req.header['X-Forwarded-Port'] =~ '[0-9]+' {\n"\
"            env.set 'REQUEST_URI' => '%{req.header[X-Forwarded-Proto]}://%{req.host}:%{req.header[X-Forwarded-Port]}%{req.raw_path}';\n"\
"         }\n"\
"         fastcgi 'unix:\$VAR_SOCKET_FILE';\n"\
"         if request.is_handled { header.remove 'Content-Length'; }\n"\
"      } else {\n"\
"         static;\n"\
"         if request.is_handled {\n"\
"            if response.header['Content-Type'] =~ '^(.*/javascript|text/.*)(;|$)' {\n"\
"               deflate;\n"\
"            }\\n"\
"         }\n"\
"      }"
     
# Generic template (don't edit) <BEGIN>
USER starter
ONBUILD USER root
# Generic template (don't edit) </END>
