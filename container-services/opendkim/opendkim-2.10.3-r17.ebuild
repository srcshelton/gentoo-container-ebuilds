# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A milter providing DKIM signing and verification"
HOMEPAGE="http://opendkim.org/"
#SRC_URI="https://downloads.sourceforge.net/project/opendkim/${P}.tar.gz"

# The GPL-2 is for the init script, bug 425960.
LICENSE="BSD GPL-2 Sendmail-Open-Source"
KEYWORDS="amd64 ~arm x86"
#IUSE="+berkdb diffheaders erlang experimental gnutls ldap libevent libressl lmdb lua -memcached opendbx poll querycache sasl selinux +ssl static-libs stats systemd test unbound"
#RESTRICT="!test? ( test )"
SLOT="0"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	acct-group/dkimsocket
	acct-group/opendkim
	acct-user/opendkim
	acct-user/postfix"

#REQUIRED_USE="sasl? ( ldap )
#	stats? ( opendbx )
#	libevent? ( unbound )
#	querycache? ( berkdb )"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in opendkim.init.r6; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	default

	newinitd "${T}/opendkim.init.r6" opendkim
	newconfd "${FILESDIR}/opendkim.confd" opendkim

	dodir /etc/opendkim
	keepdir /var/lib/opendkim

	# The OpenDKIM data (particularly, your keys) should be read-only to
	# the UserID that the daemon runs as.
	fowners root:opendkim /var/lib/opendkim
	fperms 750 /var/lib/opendkim

	insinto /etc/opendkim
	doins "${FILESDIR}/opendkim.conf"
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSION} ]]; then
		elog "If you want to sign your mail messages and need some help"
		elog "please run:"
		elog "	service ${PN} configure"
		elog "It will help you create your key and give you hints on how"
		elog "to configure your DNS and MTA."

		elog "If you are using a local (UNIX) socket, then you will"
		elog "need to make sure that your MTA has read/write access"
		elog "to the socket file. This is best accomplished by creating"
		elog "a completely-new group with only your MTA user and the"
		elog "\"opendkim\" user in it. Step-by-step instructions can be"
		elog "found on our Wiki, at https://wiki.gentoo.org/wiki/OpenDKIM ."
	else
		ewarn "The user account for the OpenDKIM daemon has changed"
		ewarn "from \"milter\" to \"opendkim\" to prevent unrelated services"
		ewarn "from being able to read your private keys. You should"
		ewarn "adjust your existing configuration to use the \"opendkim\""
		ewarn "user and group, and change the permissions on"
		ewarn "${ROOT%/}/var/lib/opendkim to root:opendkim with mode 0750."
		ewarn "The owner and group of the files within that directory"
		ewarn "will likely need to be adjusted as well."
	fi

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
