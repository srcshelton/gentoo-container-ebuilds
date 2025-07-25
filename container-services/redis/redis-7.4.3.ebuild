# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A persistent caching system, key-value, and data structures database"
HOMEPAGE="
	https://redis.io
	https://github.com/redis/redis
"
#SRC_URI="https://github.com/redis/redis/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Boost-1.0 SSPL-1"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="amd64 ~arm ~arm64 ~hppa ~loong ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux"
#IUSE="+jemalloc selinux ssl systemd tcmalloc test +tmpfiles"
#RESTRICT="!test? ( test )"

COMMON_DEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
"

RDEPEND="
	${COMMON_DEPEND}
	acct-group/redis
	acct-user/redis
	!dev-db/redis
"

BDEPEND="
	acct-group/redis
	acct-user/redis
"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in redis.initd-6_common redis-sentinel.initd-r1_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	insinto /etc/redis
	newins "${FILESDIR}/redis.conf-7.4.1" redis.conf
	newins "${FILESDIR}/sentinel.conf-7.4.1" sentinel.conf
	use prefix || fowners -R redis:redis /etc/redis /etc/redis/{redis,sentinel}.conf
	fperms 0750 /etc/redis
	fperms 0644 /etc/redis/{redis,sentinel}.conf

	newconfd "${FILESDIR}/redis.confd-r2" redis
	newinitd "${T}/redis.initd-6_common" redis

	newconfd "${FILESDIR}/redis-sentinel.confd-r1" redis-sentinel
	newinitd "${T}/redis-sentinel.initd-r1_common" redis-sentinel

	insinto /etc/logrotate.d/
	newins "${FILESDIR}/${PN}.logrotate" "${PN}"

	if use prefix; then
		diropts -m0750
	else
		diropts -m0750 -o redis -g redis
	fi
	keepdir /var/{log,lib}/redis
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
