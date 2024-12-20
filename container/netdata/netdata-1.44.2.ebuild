# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#SRC_URI="https://github.com/netdata/${PN}/releases/download/v${PV}/${PN}-v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}"
KEYWORDS="amd64 arm64 ~ppc64 ~riscv ~x86"

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata
	https://github.com/netdata/go.d.plugin
	https://my-netdata.io/"

LICENSE="GPL-3+ Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
#IUSE="bind cloud +compression cpu_flags_x86_sse2 cups +dbengine dhcp dovecot +go ipmi +jsonc mongodb mysql nfacct nodejs nvme podman postgres prometheus +python sensors systemd tor xen"

COMMON_DEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
"

RDEPEND="
	${COMMON_DEPEND}
	acct-group/netdata
	acct-user/netdata
	!net-analyzer/netdata
"

BDEPEND="
	acct-group/netdata
	acct-user/netdata
"

src_prepare() {
	local f

	for f in netdata.initd-r1_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	keepdir /var/log/netdata
	fowners -Rc netdata:netdata /var/log/netdata
	keepdir /var/lib/netdata/registry
	fowners -Rc netdata:netdata /var/lib/netdata

	newinitd "${T}/${PN}.initd-r1_common" "${PN}"
	newconfd "${FILESDIR}/${PN}.confd" "${PN}"

	echo "CONFIG_PROTECT=\"${EPREFIX}/usr/libexec/netdata/conf.d\"" > \
		"${T}"/99netdata
	doenvd "${T}"/99netdata
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

# vi: set diffopt=filler,iwhite:
