# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A program to scan messages for Unsolicited Commercial E-mail content"
HOMEPAGE="http://www.worlddesign.com/index.cfm/rd/mta/spampd.htm
	https://github.com/mpaperno/spampd"
#SRC_URI="https://github.com/mpaperno/spampd/archive/${PV}.tar.gz -> ${P}.tar.gz"
#RESTRICT="mirror"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~ppc x86"
#IUSE="html systemd"

DEPEND="container-services/spamassassin:="
RDEPEND="${DEPEND}
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!mail-filter/spampd"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in init-r1_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			-e "s#@PPVR@#$( best_version -r container-services/spamassassin | sed 's|^container-services/spamassassin-||' )#" \
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
