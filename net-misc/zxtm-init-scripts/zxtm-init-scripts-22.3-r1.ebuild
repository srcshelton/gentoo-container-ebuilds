# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Pulse Secure/Ivanti Virtual Traffic Manager (formerly Zeus ZXTM)"
HOMEPAGE="https://www.pulsesecure.net/products/virtual-traffic-manager/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
IUSE="+perl saveconfig"

# Runtime dependency for included alerting script
RDEPEND="
	perl? (
		>=dev-perl/Net-Twitter-Lite-0.12006
		dev-perl/File-HomeDir
		dev-perl/Net-OAuth
		dev-perl/URI
		virtual/perl-Data-Dumper
		virtual/perl-Scalar-List-Utils
		saveconfig? ( dev-perl/Config-Simple )
	)
"

S="${WORKDIR}"

ZEUSHOME="/opt/zeus"

src_install() {
	newconfd "${FILESDIR}"/zxtm.confd zxtm
	newinitd "${FILESDIR}"/zxtm.initd zxtm

	if use perl; then
		insinto "${ZEUSHOME}/zxtm-${PVR/-r/R}/conf/actions/"
		newins "${FILESDIR}"/tweet.action Tweet
		fperms 0600 "${ZEUSHOME}/zxtm-${PVR/-r/R}/conf/actions/Tweet"

		insinto "${ZEUSHOME}/zxtm-${PVR/-r/R}/conf/actionprogs/"
		doins "${FILESDIR}"/tweet.pl
		fperms 0711 "${ZEUSHOME}/zxtm-${PVR/-r/R}/conf/actionprogs/tweet.pl"
	fi
}
