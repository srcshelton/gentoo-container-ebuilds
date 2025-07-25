# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

#### The data in the files/ subdirectory of this ebuild are a combination ####
#### of those from dev-lang/php and app-eselect/eselect-php               ####

EAPI=8

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

SLOT="$(ver_cut 1-2)"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos"

S="${WORKDIR}"

# We can build the following SAPIs in the given order
#SAPIS="fpm"

# SAPIs and SAPI-specific USE flags (cli SAPI is default on):
#IUSE="acl apache2 apparmor argon2 avif bcmath berkdb bzip2 calendar cdb cgi cjk +cli +ctype curl debug embed enchant exif ffi +fileinfo +filter firebird +flatfile fpm ftp gd gdbm gmp +iconv imap inifile intl iodbc ipv6 +jit kerberos ldap ldap-sasl libedit lmdb mhash mssql mysql mysqli nls oci8-instant-client odbc +opcache pcntl pdo +phar phpdbg +posix postgres qdbm readline selinux +session session-mm sharedmem +simplexml snmp soap sockets sodium spell sqlite ssl systemd sysvipc test threads tidy +tokenizer tokyocabinet truetype unicode valgrind webp +xml xmlreader xmlwriter xpm xslt zip zlib"
IUSE="bcmath +fpm gd test unicode zlib"

REQUIRED_USE="
	gd? ( zlib )
"

RESTRICT="!test? ( test )"

COMMON_DEPEND="
	container-services/lighttpd:="

RDEPEND="${COMMON_DEPEND}
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!app-eselect/eselect-php
	!dev-lang/php"

BDEPEND="${COMMON_DEPEND}"

src_prepare() {
	local f

	for f in php-fpm.init-r5_common; do
		sed \
			-e "/^\s${PN}${PVR%.*})\sPV=''$/s#''#'${PVR}'#" \
			-e "s#@CPVR@#$( best_version -r container-services/lighttpd | sed 's|^container-services/lighttpd-||' )#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	# Install env.d files
	newenvd "${FILESDIR}/20php5-envd" "20php${SLOT}"
	sed -e "s|/lib/|/$(get_libdir)/|g" -i "${ED}/etc/env.d/20php${SLOT}" || die
	sed -e "s|php5|php${SLOT}|g" -i "${ED}/etc/env.d/20php${SLOT}" || die

	newinitd "${T}"/php-fpm.init-r5_common php-fpm
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
