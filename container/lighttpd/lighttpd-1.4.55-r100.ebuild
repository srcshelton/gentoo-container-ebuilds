# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit readme.gentoo-r1

DESCRIPTION="Lightweight high-performance web server"
HOMEPAGE="https://www.lighttpd.net https://github.com/lighttpd"
#SRC_URI="https://download.lighttpd.net/lighttpd/releases-1.4.x/${P}.tar.xz"

LICENSE="BSD GPL-2"
KEYWORDS="~alpha amd64 arm ~arm64 ~hppa ~ia64 ~mips ppc ppc64 ~s390 sparc x86"
#IUSE="bzip2 dbi doc fam gdbm geoip ipv6 kerberos ldap libev libressl lua memcached minimal mmap mysql pcre php postgres rrdtool sasl selinux sqlite ssl systemd test webdav xattr zlib"
IUSE="fam ipv6 php"
#RESTRICT="!test? ( test )"
SLOT="0"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	acct-group/lighttpd
	acct-user/lighttpd"

S="${WORKDIR}"

# update certain parts of lighttpd.conf based on conditionals
update_config() {
	local config="${D}/etc/lighttpd/lighttpd.conf"

	# enable php/mod_fastcgi settings
	use php && { sed -i -e 's|#.*\(include.*fastcgi.*$\)|\1|' ${config} || die; }

	# enable stat() caching
	use fam && { sed -i -e 's|#\(.*stat-cache.*$\)|\1|' ${config} || die; }

	# automatically listen on IPv6 if built with USE=ipv6. Bug #234987
	use ipv6 && { sed -i -e 's|# server.use-ipv6|server.use-ipv6|' ${config} || die; }
}

pkg_setup() {
	DOC_CONTENTS="IPv6 migration guide:\n
		http://redmine.lighttpd.net/projects/lighttpd/wiki/IPv6-Config"
}

src_prepare() {
	local f='' PHP_TARGETS="${PHP_TARGETS:-$( portageq envvar PHP_TARGETS )}"

	for f in lighttpd.initd_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			-e "s#@PPV@#${PHP_TARGETS##* }#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	default

	# init script stuff
	newinitd "${T}"/lighttpd.initd_common lighttpd
	newconfd "${FILESDIR}"/lighttpd.confd lighttpd
	use fam && has_version app-admin/fam && \
		{ sed -i 's/after famd/need famd/g' "${D}"/etc/init.d/lighttpd || die; }

	# configs
	insinto /etc/lighttpd
	doins "${FILESDIR}"/conf/lighttpd.conf
	doins "${FILESDIR}"/conf/mime-types.conf
	doins "${FILESDIR}"/conf/mod_cgi.conf
	doins "${FILESDIR}"/conf/mod_fastcgi.conf

	# update lighttpd.conf directives based on conditionals
	update_config

	# docs
	use ipv6 && readme.gentoo_create_doc

	# logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/lighttpd.logrotate-r1 lighttpd

	keepdir /var/l{ib,og}/lighttpd # /var/www/localhost/htdocs
	fowners lighttpd:lighttpd /var/l{ib,og}/lighttpd
	fperms 0750 /var/l{ib,og}/lighttpd
}

pkg_postinst() {
	use ipv6 && readme.gentoo_print_elog

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
