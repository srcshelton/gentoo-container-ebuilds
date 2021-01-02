# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#MY_P="Mail-SpamAssassin-${PV//_/-}"
DESCRIPTION="An extensible mail filter which can identify and tag spam"
HOMEPAGE="https://spamassassin.apache.org/"
#SRC_URI="mirror://apache/spamassassin/source/${MY_P}.tar.bz2"

LICENSE="Apache-2.0 GPL-2"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ppc ppc64 s390 sparc x86 ~amd64-linux ~x86-linux"
#IUSE="berkdb cron ipv6 ldap libressl mysql postgres qmail sqlite ssl systemd test"
IUSE="cron mysql postgres"
#RESTRICT="!test? ( test )"
SLOT="0"

# The Makefile.PL script checks for dependencies, but only fails if a
# required (i.e. not optional) dependency is missing. We therefore
# require most of the optional modules only at runtime.
RDEPEND="
	|| ( app-emulation/podman app-emulation/docker )
	acct-user/spamd
	acct-group/spamd"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in 3.4.1-spamd.init-r3; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	default

	# Create the stub dir used by sa-update and friends
	keepdir /var/lib/spamassassin

	dosym mail/spamassassin /etc/spamassassin

	# Add the init and config scripts.
	newinitd "${T}/3.4.1-spamd.init-r3" spamd
	newconfd "${FILESDIR}/3.4.1-spamd.conf-r1" spamd

	insinto /etc/mail/spamassassin/
	doins "${FILESDIR}"/geoip.cf
	insopts -m0400
	newins "${FILESDIR}"/secrets.cf secrets.cf.example

	# Create the directory where sa-update stores its GPG key (if you
	# choose to import one). If this directory does not exist, the
	# import will fail. This is bug 396307. We expect that the import
	# will be performed as root, and making the directory accessible
	# only to root prevents a warning on the command-line.
	diropts -m0700
	dodir /etc/mail/spamassassin/sa-update-keys

	if use cron; then
		# Install the cron job if they want it.
		exeinto /etc/cron.daily
		newexe "${FILESDIR}/update-spamassassin-rules-r1.cron" \
			   update-spamassassin-rules
	fi
}

pkg_preinst() {
	if use mysql || use postgres ; then
		local _awlwarn=0
		local _v
		for _v in ${REPLACING_VERSIONS}; do
			if ver_test "${_v}" -lt "3.4.3"; then
				_awlwarn=1
				break
			fi
		done
		if [[ ${_awlwarn} == 1 ]] ; then
			ewarn 'If you used AWL before 3.4.3, the SQL schema has changed.'
			ewarn 'You will need to manually ALTER your tables for them to'
			ewarn 'continue working.  See the UPGRADE documentation for'
			ewarn 'details.'
			ewarn
		fi
	fi
}

pkg_postinst() {
	elog
	elog 'No rules are installed by default. You will need to run sa-update'
	elog 'at least once, and most likely configure SpamAssassin before it'
	elog 'will work.'

	if ! use cron; then
		elog
		elog 'You should consider a cron job for sa-update. One is provided'
		elog 'for daily updates if you enable the "cron" USE flag.'
	fi
	elog
	elog 'Configuration and update help can be found on the wiki:'
	elog
	elog '  https://wiki.gentoo.org/wiki/SpamAssassin'
	elog

	if use mysql || use postgres ; then
		local _v
		for _v in ${REPLACING_VERSIONS}; do
			if ver_test "${_v}" -lt "3.4.3"; then
				ewarn
				ewarn 'If you used AWL before 3.4.3, the SQL schema has changed.'
				ewarn 'You will need to manually ALTER your tables for them to'
				ewarn 'continue working.  See the UPGRADE documentation for'
				ewarn 'details.'
				ewarn

				# show this only once
				break
			fi
		done
	fi

	ewarn 'If this version of SpamAssassin causes permissions issues'
	ewarn 'with your user configurations or bayes databases, then you'
	ewarn 'may need to set SPAMD_RUN_AS_ROOT=true in your OpenRC service'
	ewarn 'configuration file, or remove the --username and --groupname'
	ewarn 'flags from the SPAMD_OPTS variable in your systemd service'
	ewarn 'configuration file.'

	if [[ ! ~spamd -ef "${ROOT}/var/lib/spamd" ]] ; then
		ewarn "The spamd user's home folder has been moved to a new location."
		elog
		elog "The acct-user/spamd package should have relocated it for you,"
		elog "but may have failed because your spamd daemon was running."
		elog
		elog "To fix this:"
		elog " - Stop your spamd daemon"
		elog " - emerge -1 acct-user/spamd"
		elog " - Restart your spamd daemon"
		elog " - Remove the old home folder if you want"
		elog "     rm -rf \"${ROOT}/home/spamd\""
	fi
	if [[ -e "${ROOT}/home/spamd" ]] ; then
		ewarn
		ewarn "The spamd user's home folder has been moved to a new location."
		elog
		elog "  Old Home: ${ROOT}/home/spamd"
		elog "  New Home: ${ROOT}/var/lib/spamd"
		elog
		elog "You may wish to migrate your data to the new location:"
		elog " - Stop your spamd daemon"
		elog " - Re-emerge acct-user/spamd to ensure the home folder has been"
		elog "   updated to the new location, now that the daemon isn't running:"
		elog "     # emerge -1 acct-user/spamd"
		elog "     # echo ~spamd"
		elog " - Migrate the contents from the old location to the new home"
		elog "   For example:"
		elog "     # cp -Rpi \"${ROOT}/home/spamd/\" \"${ROOT}/var/lib/\""
		elog " - Remove the old home folder"
		elog "     # rm -rf \"${ROOT}/home/spamd\""
		elog " - Restart your spamd daemon"
		elog
		elog "If you do not wish to migrate data, you should remove the old"
		elog "home folder from your system as it is not used."
	fi

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/mail/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}

# vi: set diffopt=iwhite,filler:
