# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#COMMIT="eb420c5dee57dd54e6f63bad5d74e85f5cc9535d"
DESCRIPTION="Postgrey is a Postfix policy server implementing greylisting"
HOMEPAGE="http://postgrey.schweikert.ch/"
#SRC_URI="https://github.com/schweikert/postgrey/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
SRC_URI="https://raw.githubusercontent.com/schweikert/postgrey/master/postgrey_whitelist_clients -> ${P}.postgrey_whitelist_clients.txt
	https://raw.githubusercontent.com/schweikert/postgrey/master/postgrey_whitelist_recipients -> ${P}.postgrey_whitelist_recipients.txt"
RESTRICT="mirror"

LICENSE="GPL-2"
KEYWORDS="amd64 ~hppa ~ppc ppc64 ~x86"
#IUSE="systemd"
SLOT="0"

BDEPEND="sys-apps/grep"
RDEPEND="
	|| ( app-emulation/podman app-emulation/docker )
	app-emulation/container-init-scripts
	acct-group/postgrey
	acct-user/postgrey
	acct-user/postfix"

S="${WORKDIR}"

# Yes, for some reason the init & conf files really do have the extension 'new'

src_prepare() {
	local f

	for f in postgrey-1.34-r3.rc.new_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	local year=''

	year="$(
		tac "${PORTAGE_TMPDIR}/portage/${CATEGORY}/${PF}/distdir/${P}.postgrey_whitelist_clients.txt" |
		grep -m 1 -E -- '^# 20(1[0-9]|2[0-9])-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]): ' |
		cut -d' ' -f 2 |
		cut -d':' -f 1
	)"

	# postfix configuration
	diropts -o root -g root -m 0755
	dodir /etc/postfix
	insopts -o root -g ${PN} -m 0660
	insinto /etc/postfix/
	if [ -n "${year:-}" ]; then
		newins "${PORTAGE_TMPDIR}/portage/${CATEGORY}/${PF}/distdir/${P}.postgrey_whitelist_clients.txt" "postgrey_whitelist_clients.${year}"
		dosym "postgrey_whitelist_clients.${year}" /etc/postfix/postgrey_whitelist_clients
	else
		newins "${PORTAGE_TMPDIR}/portage/${CATEGORY}/${PF}/distdir/${P}.postgrey_whitelist_clients.txt" postgrey_whitelist_clients
	fi
	newins "${PORTAGE_TMPDIR}/portage/${CATEGORY}/${PF}/distdir/${P}.postgrey_whitelist_recipients.txt" postgrey_whitelist_recipients

	# init.d + conf.d files
	insopts -o root -g root -m 0755
	newinitd "${T}/${PN}-1.34-r3.rc.new_common" ${PN}
	insopts -o root -g root -m 0640
	newconfd "${FILESDIR}"/${PN}.conf.new ${PN}

	# postgrey data/DB in /var - also created by acct-user/postgrey
	diropts -m0770 -o ${PN} -g ${PN}
	dodir /var/spool/postfix/${PN}
	keepdir /var/spool/postfix/${PN}
	fowners postgrey:postgrey /var/spool/postfix/${PN}
	fperms 0770 /var/spool/postfix/${PN}
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/postfix"
	einfo "    /var/run/${PN}"
	einfo "    /var/spool/postfix/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
