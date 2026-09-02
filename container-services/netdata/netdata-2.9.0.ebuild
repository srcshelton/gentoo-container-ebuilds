# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

S="${WORKDIR}"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~riscv ~x86"

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata https://my-netdata.io/"

LICENSE="GPL-3+ MIT BSD dashboard? ( NCUL1 )"
SLOT="0"
#IUSE="ap apcups -beanstalkd bind bpf +compression cpu_flags_arm_neon cpu_flags_x86_avx cpu_flags_x86_sse2 cpu_flags_x86_sse4_2 cups +dashboard +dbengine -debug -demo dhcp dovecot firehol +go ipmi ipset +jsonc lto lxc +machine-learning mongodb mysql nfacct nginx nodejs nvme -opentelemetry podman postfix postgres prometheus +python qos sensors smart snmp systemd tor xen"
IUSE='+dashboard'

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
