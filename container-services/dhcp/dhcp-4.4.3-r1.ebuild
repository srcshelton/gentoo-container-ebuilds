# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#MY_PV="${PV//_alpha/a}"
#MY_PV="${MY_PV//_beta/b}"
#MY_PV="${MY_PV//_rc/rc}"
#MY_PV="${MY_PV//_p/-P}"
#MY_P="${PN}-${MY_PV}"

DESCRIPTION="ISC Dynamic Host Configuration Protocol (DHCP) client/server"
HOMEPAGE="https://www.isc.org/dhcp"
#SRC_URI="ftp://ftp.isc.org/isc/dhcp/${MY_P}.tar.gz
#	ftp://ftp.isc.org/isc/dhcp/${MY_PV}/${MY_P}.tar.gz"

LICENSE="MPL-2.0 BSD SSLeay GPL-2" # GPL-2 only for init script
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
#IUSE="+client ipv6 ldap selinux +server ssl systemd +tmpfiles vim-syntax"
IUSE="-ipv6 ldap +server"

BDEPEND="
	|| ( sys-apps/coreutils sys-apps/busybox[make-symlinks] )"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	acct-group/dhcp
	acct-user/dhcp
	!net-misc/dhcp[server(+)]"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in dhcpd.init5_common dhcrelay.init3_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	if use server; then
		newinitd "${T}"/dhcpd.init5_common dhcpd
		newinitd "${T}"/dhcrelay.init3_common dhcrelay
		newconfd "${FILESDIR}"/dhcpd.conf2 dhcpd
		newconfd "${FILESDIR}"/dhcrelay.conf dhcrelay
		# docker/podman have poor IPv6 support...
		if use ipv6; then
			dosym dhcrelay /etc/init.d/dhcrelay6
			newconfd "${FILESDIR}"/dhcrelay6.conf dhcrelay6
		fi

		sed -i "s:#@slapd@:$(usex ldap slapd ''):" "${ED}"/etc/init.d/* || die #442560
	fi

	diropts -m0750 -o dhcp -g dhcp
	keepdir /var/lib/dhcp
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
