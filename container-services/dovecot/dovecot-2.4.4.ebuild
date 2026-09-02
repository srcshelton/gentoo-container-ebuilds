# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#LUA_COMPAT=( lua5-{3..4} )
# do not add a ssl USE flag.  ssl is mandatory
#SSL_DEPS_SKIP=1
#VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/dovecot.asc
#inherit autotools dot-a eapi9-ver flag-o-matic lua-single ssl-cert systemd toolchain-funcs verify-sig

#MY_P="${P/_/.}"
#MY_PV="${PV}"
#major_minor="$(ver_cut 1-2)"

DESCRIPTION="An IMAP and POP3 server written with security primarily in mind"
HOMEPAGE="https://www.dovecot.org/"
#SRC_URI="https://www.dovecot.org/releases/${major_minor}/${MY_P}.tar.gz
#	sieve? (
#		https://pigeonhole.dovecot.org/releases/${major_minor}/${PN}-pigeonhole-${MY_PV}.tar.gz
#		verify-sig? (
#			https://pigeonhole.dovecot.org/releases/${major_minor}/${PN}-pigeonhole-${MY_PV}.tar.gz.sig
#		)
#	)
#	managesieve? (
#		https://pigeonhole.dovecot.org/releases/${major_minor}/${PN}-pigeonhole-${MY_PV}.tar.gz
#		verify-sig? (
#			https://pigeonhole.dovecot.org/releases/${major_minor}/${PN}-pigeonhole-${MY_PV}.tar.gz.sig
#		)
#	)
#	verify-sig? (
#		https://www.dovecot.org/releases/${major_minor}/${MY_P}.tar.gz.sig
#	)"
S="${WORKDIR}"
#PIEGONHOLE_S="../dovecot-pigeonhole-${MY_PV}"
LICENSE="LGPL-2.1 MIT"
SLOT="0/${PV}"
KEYWORDS="amd64 ~arm arm64 ~hppa ~mips ~ppc ppc64 ~riscv ~sparc ~x86"

#IUSE_DOVECOT_AUTH_DICT="cdb kerberos ldap lua mysql pam postgres sqlite"
#IUSE_DOVECOT_COMPRESS="lz4 zstd"
#IUSE_DOVECOT_FTS="solr stemmer textcat xapian"
#IUSE_DOVECOT_OTHER="argon2 managesieve selinux sieve static-libs suid systemd system-icu test unwind"

#IUSE="${IUSE_DOVECOT_AUTH_DICT} ${IUSE_DOVECOT_COMPRESS} ${IUSE_DOVECOT_FTS} ${IUSE_DOVECOT_OTHER}"
IUSE="managesieve pam sieve"

#REQUIRED_USE="lua? ( ${LUA_REQUIRED_USE} )"
#RESTRICT="!test? ( test )"

RDEPEND="
	acct-group/dovecot
	acct-group/dovenull
	acct-user/dovecot
	acct-user/dovenull
	net-mail/mailbase[pam?]
	!net-mail/dovecot
"

pkg_setup() {
	#use lua && lua-single_pkg_setup
	if use managesieve && ! use sieve; then
		ewarn "managesieve USE flag selected but sieve USE flag unselected"
		ewarn "sieve USE flag will be turned on"
	fi
}

src_prepare() {
	for f in dovecot.init-r6_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newinitd "${T}"/dovecot.init-r6_common dovecot
	newconfd "${FILESDIR}"/dovecot.confd dovecot

	use pam && dosym imap /etc/pam.d/dovecot

	insinto /etc/dovecot
	newins "${FILESDIR}/${PN}.conf-${PV}" "${PN}.conf"
	insinto /etc/dovecot/conf.d
	doins "${FILESDIR}/50-misc.conf"

	# logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/dovecot.logrotate dovecot

	# Update ssl cert locations
	sed -e '/cert_file/ s|/etc/dovecot|/etc/ssl/dovecot|' \
		-e '/key_file/ s|/etc/dovecot|/etc/ssl/dovecot|' \
		-i "${ED}"/etc/dovecot/dovecot.conf || die "failed to update SSL settings in dovecot.conf"
}

pkg_postinst() {
	if ver_replacing -lt 2.4 ; then
		# This is an upgrade which requires user review
		ewarn "Dovecot-2.4.x has new settings and WILL NOT work"
		ewarn "unless the configuration files are updated."
		ewarn "Please read the migration guide at:"
		ewarn "  https://doc.dovecot.org/2.4.1/installation/upgrade/2.3-to-2.4.html"
	else
		elog "Please read https://doc.dovecot.org/installation_guide/upgrading/ for upgrade notes."
	fi

	# Let's not make a new certificate if we already have one
	#if ! [[ -e "${ROOT}"/etc/ssl/dovecot/server.pem &&
	#		-e "${ROOT}"/etc/ssl/dovecot/server.key ]]
	#then
	#	einfo "Creating SSL	certificate"
	#	SSL_ORGANIZATION="${SSL_ORGANIZATION:-"Dovecot IMAP Server"}"
	#	install_cert /etc/ssl/dovecot/server
	#fi

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /etc/ssl/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
