# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#SRC_URI="https://get.bitlbee.org/src/${P}.tar.gz"
KEYWORDS="amd64 ~arm64 ppc ~ppc64 x86"
DESCRIPTION="irc to IM gateway that support multiple IM protocols"
HOMEPAGE="https://www.bitlbee.org/"

LICENSE="GPL-2"
SLOT="0"
#IUSE_PROTOCOLS="purple twitter +xmpp"
#IUSE="debug +gnutls ipv6 libevent nss otr +plugins purple selinux systemd test twitter xinetd +xmpp"
#RESTRICT="!test? ( test )"

BDEPEND="
	acct-group/bitlbee
	acct-user/bitlbee
"

RDEPEND="${BDEPEND}
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!net-im/bitlbee"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in bitlbee.initd-r2_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	keepdir /var/lib/bitlbee
	fperms 700 /var/lib/bitlbee
	fowners bitlbee:bitlbee /var/lib/bitlbee

	newinitd "${T}"/bitlbee.initd-r2_common bitlbee
	newconfd "${FILESDIR}"/bitlbee.confd-r2 bitlbee

	insinto /etc/bitlbee
	doins "${FILESDIR}"/bitlbee.conf
	doins "${FILESDIR}"/motd.txt
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}

