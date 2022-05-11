# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7


DESCRIPTION="Proxy IMAP transactions between an IMAP client and an IMAP server"
HOMEPAGE="https://sourceforge.net/projects/squirrelmail/"
#SRC_URI="https://sourceforge.net/code-snapshots/svn/s/sq/squirrelmail/code/squirrelmail-code-r${PV#*_p}-trunk.zip"

LICENSE="GPL-2"
KEYWORDS="amd64 ~ppc x86"
#IUSE="kerberos ssl +tcpd"
#RESTRICT="mirror"
SLOT="0"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!net-mail/imapproxy"

S="${WORKDIR}"

src_prepare() {
	for f in imapproxy.initd_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newinitd "${T}"/imapproxy.initd_common imapproxy
	newconfd "${FILESDIR}"/imapproxy.confd imapproxy

	insinto /etc/imapproxy/
	newins "${FILESDIR}/${PN}.conf" imapproxyd.conf
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /etc/ssl"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
