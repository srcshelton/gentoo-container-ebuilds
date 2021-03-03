# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

KEYWORDS="amd64"
DESCRIPTION="Pulse Secure Virtual Traffic Manager (formerly Zeus ZXTM)"
HOMEPAGE="https://www.pulsesecure.net/products/virtual-traffic-manager/"

LICENSE="Pulse"
SLOT="0"

RDEPEND="
	|| ( app-emulation/podman app-emulation/docker )
	app-emulation/container-init-scripts"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in zxtm.initd_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	dodir /etc/zeus/{admin,stingray,zxtm}
	dodir /etc/ssl/zeus/{client,server}
	dodir /var/cache/zeus/admin
	dodir /var/lib/zeus/stingray
	dodir /var/log/zeus/{admin,updater,zxtm} /var/log/zeus/stingray/{generic,log,master}
	fperms 0700 \
		/var/log/zeus/admin \
		/var/log/zeus/zxtm
	fowners root:sys \
		/var/cache/zeus/admin \
		/var/lib/zeus/stingray \
		/var/log/zeus/admin \
		/var/log/zeus/stingray/{generic,log,master} \
		/var/log/zeus/updater

	newinitd "${T}"/zxtm.initd_common zxtm
	#newconfd "${FILESDIR}"/zxtm.confd zxtm
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /etc/ssl/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/cache/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}

