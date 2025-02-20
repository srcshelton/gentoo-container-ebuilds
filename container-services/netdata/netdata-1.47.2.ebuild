# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#if [[ ${PV} == *9999 ]] ; then
#	EGIT_REPO_URI="https://github.com/netdata/${PN}.git"
#else
#	# ... from packaging/cmake/Modules/NetdataEBPFLegacy.cmake
#	EBPF_CO_RE_VERSION="v1.4.5.1"
#	EBPF_VERSION="v1.4.5.1"
#	LIBBPF_VERSION="1.4.5p_netdata"
#	GO_VENDOR_VERSION="1.47.1"
#	EBPF_CO_RE_TARBALL="netdata-ebpf-co-re-glibc-${EBPF_CO_RE_VERSION}.tar.xz"
#	EBPF_TARBALL="netdata-kernel-collector-glibc-${EBPF_VERSION}.tar.xz"
#	LIBBPF_TARBALL="${LIBBPF_VERSION}.tar.gz"  # N.B. 1.4.5 only lacks an initial 'v' :(
#	SRC_URI="
#		https://github.com/netdata/${PN}/releases/download/v${PV}/${PN}-v${PV}.tar.gz -> ${P}.tar.gz
#		https://github.com/netdata/ebpf-co-re/releases/download/${EBPF_CO_RE_VERSION}/${EBPF_CO_RE_TARBALL}
#		https://github.com/netdata/kernel-collector/releases/download/${EBPF_VERSION}/${EBPF_TARBALL}
#		https://github.com/netdata/libbpf/archive/${LIBBPF_TARBALL} -> ${PN}-libbpf-${LIBBPF_TARBALL}
#		https://github.com/srcshelton/netdata/releases/download/v${GO_VENDOR_VERSION}/${PN}-${GO_VENDOR_VERSION}-vendor.tar.xz
#	"
#	S="${WORKDIR}/${PN}-v${PV}"
	S="${WORKDIR}"
	KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv ~x86"
#fi

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata https://my-netdata.io/"

LICENSE="GPL-3+ MIT BSD"
SLOT="0"
#IUSE="aclk ap apcups bind bpf cloud +compression cpu_flags_x86_sse2 cups +dbengine dhcp dovecot +go ipmi +jsonc lxc mongodb mysql nfacct nginx nodejs nvme podman postfix postgres prometheus +python qos sensors smart systemd tor xen"

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

	insinto /etc/logrotate.d
	newins "${FILESDIR}"/netdata.logrotate netdata

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
