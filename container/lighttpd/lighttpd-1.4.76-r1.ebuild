# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit readme.gentoo-r1

DESCRIPTION="Lightweight high-performance web server"
HOMEPAGE="https://www.lighttpd.net https://github.com/lighttpd"
#SRC_URI="
#	https://download.lighttpd.net/lighttpd/releases-$(ver_cut 1-2).x/${P}.tar.xz
#	verify-sig? ( https://download.lighttpd.net/lighttpd/releases-$(ver_cut 1-2).x/${P}.tar.xz.asc )
#"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~arm64 ~hppa ~ia64 ~loong ~mips ppc ppc64 ~riscv ~s390 ~sparc x86"
#IUSE="+brotli dbi gnutls kerberos ldap libdeflate +lua maxminddb mbedtls +nettle nss +pcre php sasl selinux ssl systemd test unwind webdav xattr +zlib zstd"
IUSE="php"
#RESTRICT="!test? ( test )"

BDEPEND="
	acct-group/lighttpd
	acct-user/lighttpd
"
RDEPEND="
	${BDEPEND}
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!www-servers/lighttpd
"

S="${WORKDIR}"

# update certain parts of lighttpd.conf based on conditionals
update_config() {
	local config="${ED}/etc/lighttpd/lighttpd.conf"

	# Automatically listen on IPv6 if built with USE=ipv6 (which we now always do)
	# bug #234987
	sed -i -e 's|# server.use-ipv6|server.use-ipv6|' ${config} || die
}

pkg_setup() {
	DOC_CONTENTS="IPv6 migration guide:\n
		https://wiki.lighttpd.net/IPv6-Config
	"
}

src_prepare() {
	# See https://github.com/InBetweenNames/gentooLTO/issues/883
	local initd='' regex='' f=''

	if use php; then
		local PHP_TARGETS="${PHP_TARGETS:-"$( $( type -pf portageq ) envvar PHP_TARGETS )"}"
		initd="lighttpd+php.initd-r2_common"
		regex="s#@PVR@#${PVR}# ; s#@PPV@#${PHP_TARGETS##* }#"
	else
		initd="lighttpd.initd-r2_common"
		regex="s#@PVR@#${PVR}#"
	fi
	for f in "${initd}"; do
		sed -e "${regex}" \
				"${FILESDIR}/${f}" > "${T}/${f/+php}" ||
			die "sed with regex '${regex}' failed: ${?}"
	done

	default
}

src_install() {
	default

	# Init script stuff
	newinitd "${T}"/lighttpd.initd-r2_common lighttpd
	newconfd "${FILESDIR}"/lighttpd.confd lighttpd

	# Configs
	insinto /etc/lighttpd
	newins "${FILESDIR}"/conf/lighttpd.conf-r3 lighttpd.conf
	doins "${FILESDIR}"/conf/mod_cgi.conf
	doins "${FILESDIR}"/conf/mod_fastcgi.conf

	# Update lighttpd.conf directives based on conditionals
	update_config

	# Docs
	readme.gentoo_create_doc

	# Logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/lighttpd.logrotate-r1 lighttpd

	keepdir /var/l{ib,og}/lighttpd # /var/www/localhost/htdocs
	fowners lighttpd:lighttpd /var/l{ib,og}/lighttpd
	fperms 0750 /var/l{ib,og}/lighttpd
}

pkg_postinst() {
	readme.gentoo_print_elog

	elog
	elog "Upstream has deprecated a number of features. They are not missing"
	elog "but have been migrated to other mechanisms. Please see upstream"
	elog "changelog for details."
	elog "https://www.lighttpd.net/2022/1/19/1.4.64/"

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}

# vi: set diffopt=filler,iwhite:
