# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#PYTHON_COMPAT=( python3_{10..13} )
#
#inherit autotools flag-o-matic prefix python-single-r1 systemd

DESCRIPTION="Distribute compilation of C code across several machines on a network"
HOMEPAGE="https://github.com/distcc/distcc"
#SRC_URI="https://github.com/distcc/distcc/releases/download/v${PV}/${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
#IUSE="gssapi gtk hardened ipv6 selinux xinetd zeroconf"
IUSE="zeroconf"
#REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!sys-devel/distcc"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in distccd.initd_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	#sed \
	#	-e "s:@EPREFIX@:${EPREFIX:-/}:" \
	#	"${FILESDIR}/distcc-config-r1" > "${T}/distcc-config" || die

	#hprefixify update-distcc-symlinks.py src/{serve,daemon}.c
	#python_fix_shebang update-distcc-symlinks.py "${T}/distcc-config"

	default
}

src_install() {
	newinitd "${T}/distccd.initd_common" distccd

	cp "${FILESDIR}/distccd.confd" "${T}/distccd" || die
	if use zeroconf; then
		cat >> "${T}/distccd" <<-EOF || die

		# Enable zeroconf support in distccd
		DISTCCD_OPTS="\${DISTCCD_OPTS} --zeroconf"
		EOF
	fi
	doconfd "${T}/distccd"

	#newenvd - 02distcc <<-EOF || die
	## This file is managed by distcc-config; use it to change these settings.
	## DISTCC_LOG and DISTCC_DIR should not be set.
	#DISTCC_VERBOSE="${DISTCC_VERBOSE:-0}"
	#DISTCC_FALLBACK="${DISTCC_FALLBACK:-1}"
	#DISTCC_SAVE_TEMPS="${DISTCC_SAVE_TEMPS:-0}"
	#DISTCC_TCP_CORK="${DISTCC_TCP_CORK}"
	#DISTCC_SSH="${DISTCC_SSH}"
	#UNCACHED_ERR_FD="${UNCACHED_ERR_FD}"
	#DISTCC_ENABLE_DISCREPANCY_EMAIL="${DISTCC_ENABLE_DISCREPANCY_EMAIL}"
	#DCC_EMAILLOG_WHOM_TO_BLAME="${DCC_EMAILLOG_WHOM_TO_BLAME}"
	#EOF
	#
	#keepdir /usr/lib/distcc
	#
	#dobin "${T}/distcc-config"
}

pkg_postinst() {
	elog
	elog "Tips on using distcc with Gentoo can be found at"
	elog "https://wiki.gentoo.org/wiki/Distcc"
	elog
	elog "distcc-pump is broken and no longer installed."
	elog
	elog "To use the distccmon programs with Gentoo you should use this command:"
	elog "# DISTCC_DIR=\"${DISTCC_DIR:-${BUILD_PREFIX}/.distcc}\" distccmon-text 5"

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
