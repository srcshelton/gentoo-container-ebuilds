# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Daemon for monitoring and adaptive tuning of system devices"
HOMEPAGE="https://github.com/redhat-performance/tuned"
#SRC_URI="https://github.com/redhat-performance/tuned/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

#IUSE="+dbus gtk +tmpfiles"
#REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!sys-apps/tuned[server]
"

#RESTRICT="test"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in "${PN}.initd_common"; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newinitd "${T}/${PN}.initd_common" "${PN}"
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
