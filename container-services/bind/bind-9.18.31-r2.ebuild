# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#MY_PV="${PV/_p/-P}"
#MY_PV="${MY_PV/_rc/rc}"

DESCRIPTION="Berkeley Internet Name Domain - Name Server"
HOMEPAGE="https://www.isc.org/software/bind"
#SRC_URI="https://downloads.isc.org/isc/bind9/${PV}/${P}.tar.xz"
#S="${WORKDIR}/${PN}-${MY_PV}"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux"
#IUSE="+caps dnstap doc doh fixed-rrset idn jemalloc geoip gssapi lmdb selinux static-libs test xml"
#RESTRICT="!test? ( test )"

BDEPEND="
	acct-group/named
	acct-user/named"

RDEPEND="${BDEPEND}
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!<net-dns/bind-9.18
	!>=net-dns/bind-9.18[server]"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in named.init-r15_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	default

	insinto /etc/bind
	newins "${FILESDIR}"/named.conf-r8 named.conf
	doins "${FILESDIR}"/named.conf.auth

	newinitd "${T}"/named.init-r15_common named
	newconfd "${FILESDIR}"/named.confd-r8 named

	newenvd "${FILESDIR}"/10bind.env 10bind

	#
	# /var/state/bind
	#
	# These need to remain for now because CONFIG_PROTECT won't
	# save them and we shipped configs for years containing references
	# to them.
	#
	# ftp://ftp.rs.internic.net/domain/named.cache:
	insinto /var/state/bind
	newins "${FILESDIR}"/named.cache-r4 named.cache
	# bug #450406
	dosym named.cache /var/state/bind/root.cache

	insinto /var/state/bind/pri
	newins "${FILESDIR}"/localhost.zone-r3 localhost.zone

	dosym -r /var/state/bind/pri /etc/bind/pri
	dosym -r /var/state/bind/sec /etc/bind/sec
	dosym -r /var/state/bind/dyn /etc/bind/dyn
	keepdir /var/state/bind/{pri,sec,dyn} /var/log/named

	# /etc/bind is set to root:named by acct-user/named
	fowners root:named /{etc,var/state}/bind /var/log/named /var/state/bind/{sec,pri,dyn}
	#fowners root:named /etc/bind/{bind.keys,named.conf,named.conf.auth}
	#fperms 0640 /etc/bind/{bind.keys,named.conf,named.conf.auth}
	fowners root:named /etc/bind/{named.conf,named.conf.auth}
	fperms 0640 /etc/bind/{named.conf,named.conf.auth}
	fperms 0750 /etc/bind /var/state/bind/pri
	fperms 0770 /var/log/named /var/state/bind/{,sec,dyn}

	exeinto /usr/libexec
	doexe "${FILESDIR}/generate-rndc-key.sh"
}

pkg_postinst() {
	# This must be run from within the container...
	#
	#if ! [[ -f "${EROOT}/etc/bind/rndc.key" ]]; then
	#	if [[ -f "${EROOT}/etc/bind/rndc.conf" ]]; then
	#		ewarn "'${EROOT}/etc/bind/rndc.conf' exists - not generating new 'rndc.key'"
	#	else
	#		if [[ "${ROOT:-"/"}" != '/' ]]; then
	#			local -x LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${EROOT%/}/$(get_libdir):${EROOT%/}/usr/$(get_libdir)"
	#		fi
	#		einfo "Generating rndc.key ..."
	#		if "${EROOT}"/usr/sbin/rndc-confgen -a; then
	#			# rndc-confgen always creates files in /etc/bind/...
	#			chown root:named "${EPREFIX}"/etc/bind/rndc.key || die
	#			chmod 0640 "${EPREFIX}"/etc/bind/rndc.key || die
	#		fi
	#		if [[ -f "${EPREFIX}"/etc/bind/rndc.key ]] && [[ ! -f "${EROOT}"/etc/bind/rndc.key ]]; then
	#			cp -a "${EPREFIX}"/etc/bind/rndc.key "${EROOT}"/etc/bind/rndc.key
	#		fi
	#	fi
	#fi

	einfo
	einfo "You can edit /etc/conf.d/named to customize named settings"
	einfo

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/state/${PN}"
	einfo "    /var/log/named"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}

# vi: set diffopt=filler,iwhite:
