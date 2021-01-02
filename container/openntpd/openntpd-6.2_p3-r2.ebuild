# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#MY_P="${P/_p/p}"

DESCRIPTION="Lightweight NTP server ported from OpenBSD"
HOMEPAGE="http://www.openntpd.org/"
#SRC_URI="mirror://openbsd/OpenNTPD/${MY_P}.tar.gz"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~mips ppc ppc64 s390 sparc x86"
#IUSE="libressl selinux systemd"

RDEPEND="
	|| ( app-emulation/podman app-emulation/docker )
	acct-group/openntpd
	acct-user/openntpd"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in "${PN}.init.d-20080406-r6"; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newinitd "${T}/${PN}.init.d-20080406-r6" ntpd
	newconfd "${FILESDIR}/${PN}.conf.d-20080406-r6" ntpd

	insinto "/etc/${PN}"
	newins "${FILESDIR}"/ntpd.conf-1.14 ntpd.conf

	insinto /etc/logrotate.d
	newins "${FILESDIR}/${PN}.logrotate-20080406-r5" ntpd
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
