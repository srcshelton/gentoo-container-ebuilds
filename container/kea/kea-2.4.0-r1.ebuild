# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PV="${PV//_p/-P}"
MY_PV="${MY_PV/_/-}"
MY_P="${PN}-${MY_PV}"

DESCRIPTION="High-performance production grade DHCPv4 & DHCPv6 server"
HOMEPAGE="https://www.isc.org/kea/"

#PYTHON_COMPAT=( python3_{8..12} )

#inherit autotools fcaps flag-o-matic python-single-r1 systemd tmpfiles
inherit tmpfiles

#if [[ ${PV} = 9999* ]] ; then
#	inherit git-r3
#	EGIT_REPO_URI="https://gitlab.isc.org/isc-projects/kea.git"
#else
#	SRC_URI="ftp://ftp.isc.org/isc/kea/${MY_P}.tar.gz
#		ftp://ftp.isc.org/isc/kea/${MY_PV}/${MY_P}.tar.gz"
	# odd minor version = development release
	if [[ $(( $(ver_cut 2) % 2 )) -ne 1 ]] ; then
		if ! [[ "${PV}" == *_beta* || "${PV}" == *_rc* ]] ; then
			 KEYWORDS="~amd64 ~arm64 ~x86"
		fi
	fi
#fi

LICENSE="ISC BSD SSLeay GPL-2" # GPL-2 only for init script
SLOT="0"
#IUSE="benchmark debug doc examples filecaps mysql +openssl postgres +shell systemd tmpfiles test"
IUSE="tmpfiles"
#RESTRICT="!test? ( test )"

BDEPEND="
	acct-group/dhcp
	acct-user/dhcp
"
RDEPEND="
	${BDEPEND}
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!net-misc/kea
"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in kea-initd-r1_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newconfd "${FILESDIR}/${PN}-confd-r1" "${PN}"
	newinitd "${T}/${PN}-initd-r1_common" "${PN}"

	diropts -m 0750 -o root -g dhcp
	dodir /etc/kea
	insopts -m 0640 -o root -g dhcp
	insinto /etc/kea
	for f in ctrl-agent ddns-server dhcp4 dhcp6; do
		sed -e "s|@libdir@|/$(get_libdir)|g ; s|@localestatedir@|/var|g" \
			"${FILESDIR}/${PN}-${f}.conf" > "${T}/${PN}-${f}.conf"
		doins "${T}/${PN}-${f}.conf"
	done

	if use tmpfiles; then
		newtmpfiles "${FILESDIR}"/${PN}.tmpfiles.conf ${PN}.conf
	fi

	keepdir /var/lib/${PN} /var/log/${PN}
}

pkg_postinst() {
	use tmpfiles && tmpfiles_process ${PN}.conf

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}

# vi: set diffopt=filler,iwhite:
