# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#MY_P="${P/p/P}"

DESCRIPTION="An HTTP/HTTPS reverse-proxy and load-balancer"
HOMEPAGE="https://www.apsis.ch/pound.html"
#SRC_URI="https://www.apsis.ch/pound/${MY_P}.tgz"

LICENSE="BSD GPL-3"
SLOT="0"
KEYWORDS="amd64 ~hppa ~ppc x86"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!www-servers/pound"

S="${WORKDIR}"

src_prepare() {
	for f in pound.init-1.9_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newinitd "${T}"/pound.init-1.9_common pound
	newconfd "${FILESDIR}"/pound.confd pound

	insinto /etc/pound
	newins "${FILESDIR}"/pound-3.0.cfg.yaml pound.yaml
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
