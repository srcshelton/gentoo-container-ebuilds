# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

#### The data in the files/ subdirectory of this ebuild are a combination ####
#### of those from dev-lang/php and app-eselect/eselect-php               ####

EAPI="7"

DESCRIPTION="The PHP language runtime engine"
HOMEPAGE="https://www.php.net/"
#SRC_URI="https://www.php.net/distributions/${P}.tar.xz"

LICENSE="PHP-3.01
	BSD
	Zend-2.0
	bcmath? ( LGPL-2.1+ )
	fpm? ( BSD-2 )
	gd? ( gd )
	unicode? ( BSD-2 LGPL-2.1 )"
KEYWORDS="~alpha amd64 ~arm arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos"
IUSE="bcmath +fpm gd unicode"
#RESTRICT="!test? ( test )"
SLOT="$(ver_cut 1-2)"

# We can build the following SAPIs in the given order
#SAPIS="embed cli cgi fpm apache2 phpdbg"

# SAPIs and SAPI-specific USE flags (cli SAPI is default on):
#IUSE="acl apache2 argon2 bcmath berkdb bzip2 calendar cdb cgi cjk +cli coverage +ctype curl debug embed enchant exif ffi +fileinfo +filter firebird +flatfile fpm ftp gd gdbm gmp +iconv imap inifile intl iodbc ipv6 +json kerberos ldap ldap-sasl libedit libressl lmdb mhash mssql mysql mysqli nls oci8-instant-client odbc +opcache pcntl pdo +phar phpdbg +posix postgres qdbm readline selinux +session session-mm sharedmem +simplexml snmp soap sockets sodium spell sqlite ssl systemd sysvipc test threads tidy +tokenizer tokyocabinet truetype unicode webp +xml xmlreader xmlrpc xmlwriter xpm xslt zip zlib"

# FIXME: Use some derivative of virtual/httpd-php
BDEPEND="container/lighttpd:="
RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	${BDEPEND}
"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in php-fpm.init-r5; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			-e "s#@CPVR@#$( best_version -r container/lighttpd | sed 's|^container/lighttpd-||' )#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	# Install env.d files
	newenvd "${FILESDIR}/20php5-envd" "20php${SLOT}"
	sed -e "s|/lib/|/$(get_libdir)/|g" -i "${ED}/etc/env.d/20php${SLOT}" || die
	sed -e "s|php5|php${SLOT}|g" -i "${ED}/etc/env.d/20php${SLOT}" || die

	newinitd "${T}"/php-fpm.init-r5 php-fpm
	newconfd "${FILESDIR}"/php-fpm.confd php-fpm

	insinto /etc/logrotate.d/
	newins "${FILESDIR}"/php.logrotate php
	newins "${FILESDIR}"/php-fpm.logrotate php-fpm
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
