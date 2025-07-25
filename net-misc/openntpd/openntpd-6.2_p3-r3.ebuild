# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools systemd

MY_P="${P/_p/p}"

DESCRIPTION="Lightweight NTP server ported from OpenBSD"
HOMEPAGE="https://www.openntpd.org/"
SRC_URI="mirror://openbsd/OpenNTPD/${MY_P}.tar.gz"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="selinux systemd"

BDEPEND="
	sys-devel/bison"
DEPEND="
	!net-misc/ntp[-openntpd]"
RDEPEND="
	${DEPEND}
	acct-group/openntpd
	acct-user/openntpd
	selinux? ( sec-policy/selinux-ntp )"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	"${FILESDIR}/openntpd-6.2p3-fno-common.patch"
	# https://github.com/openntpd-portable/openntpd-portable/pull/75
	"${FILESDIR}"/0001-fix-incompatible-check-for-libc-compat.patch
)

src_prepare() {
	default
	eautoreconf

	# fix /run path
	#sed -i 's:/var/run/ntpd:/run/ntpd:g' src/ntpctl.8 src/ntpd.8 || die
	#sed -i 's:LOCALSTATEDIR "/run/ntpd:"/run/ntpd:' src/ntpd.h || die

	# fix ntpd.sock patch (with change needed to prevent use of /var/lib/run/openntpd/ntpd.sock)
	sed -i 's:LOCALSTATEDIR "/run/ntpd.sock":"/var/run/ntpd.sock":' src/ntpd.h || die
	sed -i 's:/run/ntpd.sock:/run/openntpd/ntpd.sock:' src/ntpctl.8 src/ntpd.h src/ntpd.8 || die

	# fix ntpd.drift path
	sed -i 's:/var/db/ntpd.drift:/var/lib/openntpd/ntpd.drift:g' src/ntpd.8 || die
	sed -i 's:"/db/ntpd.drift":"/openntpd/ntpd.drift":' src/ntpd.h || die

	# fix default config to use gentoo pool
	sed -i 's:servers pool.ntp.org:#servers pool.ntp.org:' ntpd.conf || die
	printf "\n# Choose servers announced from Gentoo NTP Pool\nservers 0.gentoo.pool.ntp.org\nservers 1.gentoo.pool.ntp.org\nservers 2.gentoo.pool.ntp.org\nservers 3.gentoo.pool.ntp.org\n" >> ntpd.conf || die

	# constraint config only works with libressl
	sed -ie 's/^constraints/#constraints/g' ntpd.conf || die
}

src_configure() {
	econf \
		--with-privsep-user=openntpd \
		--with-privsep-path=/var/lib/openntpd/chroot \
		--disable-https-constraint
}

src_install() {
	default

	rm -r "${ED}"/var || die

	newinitd "${FILESDIR}/${PN}.init.d-20080406-r6" ntpd
	newconfd "${FILESDIR}/${PN}.conf.d-20080406-r6" ntpd

	use systemd && systemd_newunit "${FILESDIR}/${PN}.service-20080406-r4" ntpd.service
}
