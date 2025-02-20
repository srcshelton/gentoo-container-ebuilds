# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..10} )

DESCRIPTION="Berkeley Internet Name Domain - Name Server"
HOMEPAGE="https://www.isc.org/software/bind https://gitlab.isc.org/isc-projects/bind9"
#SRC_URI="https://downloads.isc.org/isc/bind9/${PV}/${P}.tar.xz
#	doc? ( mirror://gentoo/dyndns-samples.tbz2 )"

LICENSE="Apache-2.0 BSD BSD-2 GPL-2 HPND ISC MPL-2.0"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm arm64 ~hppa ~ia64 ~mips ~ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux"
# -berkdb by default re bug #602682
#IUSE="berkdb +caps +dlz dnsrps dnstap doc fixed-rrset geoip geoip2 gssapi json ldap lmdb mysql odbc postgres python selinux static-libs systemd test +tmpfiles xml +zlib"
IUSE="ldap mysql postgres"

BDEPEND="
	acct-group/named
	acct-user/named"

RDEPEND="${BDEPEND}
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!net-dns/bind"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in named.init-r14_common; do
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

	# ftp://ftp.rs.internic.net/domain/named.cache:
	insinto /var/bind
	newins "${FILESDIR}"/named.cache-r3 named.cache

	insinto /var/bind/pri
	newins "${FILESDIR}"/localhost.zone-r3 localhost.zone

	newinitd "${T}"/named.init-r14_common named
	newconfd "${FILESDIR}"/named.confd-r7 named

	newenvd "${FILESDIR}"/10bind.env 10bind

	# bug 450406
	dosym named.cache /var/bind/root.cache

	dosym ../../var/bind/pri /etc/bind/pri
	dosym ../../var/bind/sec /etc/bind/sec
	dosym ../../var/bind/dyn /etc/bind/dyn
	keepdir /var/bind/{pri,sec,dyn} /var/log/named

	# /etc/bind is set to root:named by acct-user/named
	fowners root:named /{etc,var}/bind /var/log/named /var/bind/{sec,pri,dyn}
	#fowners root:named /var/bind/named.cache /var/bind/pri/localhost.zone /etc/bind/{bind.keys,named.conf}
	#fperms 0640 /var/bind/named.cache /var/bind/pri/localhost.zone /etc/bind/{bind.keys,named.conf}
	fowners root:named /var/bind/named.cache /var/bind/pri/localhost.zone /etc/bind/named.conf
	fperms 0640 /var/bind/named.cache /var/bind/pri/localhost.zone /etc/bind/named.conf
	fperms 0750 /etc/bind /var/bind/pri
	fperms 0770 /var/log/named /var/bind/{,sec,dyn}

	exeinto /usr/libexec
	doexe "${FILESDIR}/generate-rndc-key.sh"
}

pkg_postinst() {
	# This must be run from within the container...
	#
	#if [[ ! -f "${ROOT}/etc/bind/rndc.key" ]]; then
	#	if [[ -f "${ROOT}/etc/bind/rndc.conf" ]]; then
	#		ewarn "'${ROOT}/etc/bind/rndc.conf' exists - not generating new 'rndc.key'"
	#	else
	#		if [ "${ROOT}" != '/' ]; then
	#			local -x LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${ROOT%/}/$(get_libdir):${ROOT%/}/usr/$(get_libdir)"
	#		fi
	#		"${ROOT}"/usr/sbin/rndc-confgen -a
	#		# rndc-confgen always creates files in /etc/bind/...
	#		chown root:named /etc/bind/rndc.key || die
	#		chmod 0640 /etc/bind/rndc.key || die
	#		if [ -f /etc/bind/rndc.key ] && [ ! -f "${ROOT}"/etc/bind/rndc.key ]; then
	#			cp -a /etc/bind/rndc.key "${ROOT}"/etc/bind/rndc.key
	#		fi
	#	fi
	#fi

	einfo
	einfo "You can edit /etc/conf.d/named to customize named settings"
	einfo
	use mysql || use postgres || use ldap && {
		elog "If your named depends on MySQL/PostgreSQL or LDAP,"
		elog "uncomment the specified rc_named_* lines in your"
		elog "/etc/conf.d/named config to ensure they'll start before bind"
		einfo
	}

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/${PN}"
	einfo "    /var/log/named"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}

# vi: set diffopt=filler,iwhite:
