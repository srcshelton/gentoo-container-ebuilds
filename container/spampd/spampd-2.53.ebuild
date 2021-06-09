# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="spampd is a program to scan messages for Unsolicited Commercial E-mail content"
HOMEPAGE="http://www.worlddesign.com/index.cfm/rd/mta/spampd.htm"
#SRC_URI="https://github.com/mpaperno/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
KEYWORDS="amd64 ~ppc x86"
#IUSE="html systemd"
#RESTRICT="mirror"
SLOT="0"

DEPEND="container/spamassassin:="
RDEPEND="${BDEPEND}
	|| ( app-emulation/podman app-emulation/docker )
	app-emulation/container-init-scripts"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in init-r1_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			-e "s#@PPVR@#$( best_version -r container/spamassassin | sed 's|^container/spamassassin-||' )#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newinitd "${T}"/init-r1_common spampd
	newconfd "${FILESDIR}"/conf spampd
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
