# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A highly configurable replacement for syslogd/klogd"
HOMEPAGE="https://github.com/hvisage/metalog"
#SRC_URI="https://github.com/hvisage/${PN}/archive/${P}.tar.gz"

LICENSE="GPL-2"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~x64-cygwin"
#IUSE="unicode"
SLOT="0"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in metalog.initd-r1_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newsbin "${FILESDIR}"/consolelog.sh-r1 consolelog.sh

	insinto /etc/metalog
	doins "${FILESDIR}"/metalog.conf

	newinitd "${T}"/metalog.initd-r1_common metalog
	newconfd "${FILESDIR}"/metalog.confd metalog
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/log"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
