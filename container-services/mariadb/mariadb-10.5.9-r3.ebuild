# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

#### The data in the files/ subdirectory of this ebuild are a combination ####
#### of those from dev-db/mariadb and dev-db/mysql-init-scripts           ####

EAPI="7"

inherit prefix

HOMEPAGE="https://mariadb.org/"
DESCRIPTION="An enhanced, drop-in replacement for MySQL"
#PATCH_SET="https://dev.gentoo.org/~whissi/dist/${PN}/${PN}-10.5.9-patches-03.tar.xz"
#SRC_URI="https://downloads.mariadb.org/interstitial/${P}/source/${P}.tar.gz
#	${PATCH_SET}"

LICENSE="GPL-2 LGPL-2.1+"
KEYWORDS="~alpha amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris ~x86-solaris"
#IUSE="+backup bindist columnstore cracklib debug extraengine galera innodb-bzip2 innodb-lz4 innodb-lzma innodb-lzo innodb-snappy jdbc jemalloc kerberos latin1 libressl mroonga numa odbc oqgraph pam +perl profiling rocksdb s3 selinux +server sphinx sst-mariabackup sst-rsync static systemd systemtap tcmalloc test xml yassl"
IUSE="latin1 +server"
SUBSLOT="18"
SLOT="10.5/${SUBSLOT:-0}"

# dev-db/mysql-connector-c needed for my_print_defaults ...
RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	dev-db/mysql-connector-c
	acct-group/mysql
	acct-user/mysql"

S="${WORKDIR}"

mysql_init_vars() {
	MY_SHAREDSTATEDIR=${MY_SHAREDSTATEDIR="${EPREFIX}/usr/share/mariadb"}
	MY_SYSCONFDIR=${MY_SYSCONFDIR="${EPREFIX}/etc/mysql"}
	MY_LOCALSTATEDIR=${MY_LOCALSTATEDIR="${EPREFIX}/var/lib/mysql"}
	MY_LOGDIR=${MY_LOGDIR="${EPREFIX}/var/log/mysql"}

	if [[ -z "${MY_DATADIR}" ]] ; then
		MY_DATADIR=""
		if [[ -f "${MY_SYSCONFDIR}/my.cnf" ]] ; then
			MY_DATADIR=$(my_print_defaults mysqld 2>/dev/null \
				| sed -ne '/datadir/s|^--datadir=||p' \
				| tail -n1)
			if [[ -z "${MY_DATADIR}" ]] ; then
				MY_DATADIR=$(grep ^datadir "${MY_SYSCONFDIR}/my.cnf" \
				| sed -e 's/.*=\s*//' \
				| tail -n1)
			fi
		fi
		if [[ -z "${MY_DATADIR}" ]] ; then
			MY_DATADIR="${MY_LOCALSTATEDIR}"
			einfo "Using default MY_DATADIR"
		fi
		elog "MySQL MY_DATADIR is ${MY_DATADIR}"

		if [[ -z "${PREVIOUS_DATADIR}" ]] ; then
			if [[ -e "${MY_DATADIR}" ]] ; then
				# If you get this and you're wondering about it, see bug #207636
				elog "MySQL datadir found in ${MY_DATADIR}"
				elog "A new one will not be created."
				PREVIOUS_DATADIR="yes"
			else
				PREVIOUS_DATADIR="no"
			fi
			export PREVIOUS_DATADIR
		fi
	else
		if [[ ${EBUILD_PHASE} == "config" ]]; then
			local new_MY_DATADIR
			new_MY_DATADIR=$(my_print_defaults mysqld 2>/dev/null \
				| sed -ne '/datadir/s|^--datadir=||p' \
				| tail -n1)

			if [[ ( -n "${new_MY_DATADIR}" ) && ( "${new_MY_DATADIR}" != "${MY_DATADIR}" ) ]]; then
				ewarn "MySQL MY_DATADIR has changed"
				ewarn "from ${MY_DATADIR}"
				ewarn "to ${new_MY_DATADIR}"
				MY_DATADIR="${new_MY_DATADIR}"
			fi
		fi
	fi

	export MY_SHAREDSTATEDIR MY_SYSCONFDIR
	export MY_LOCALSTATEDIR MY_LOGDIR
	export MY_DATADIR
}

src_prepare() {
	local f

	for f in init.d-2.3_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	# From dev-db/mysql-init-scripts
	#

	newconfd "${FILESDIR}/conf.d-2.0" "mysql"
	newinitd "${T}/init.d-2.3_common" "mysql"

	insinto /etc/logrotate.d
	newins "${FILESDIR}/logrotate.mysql-2.3" "mysql"

	# From dev-db/mariadb
	#

	# Make sure the vars are correctly initialized
	mysql_init_vars

	# Configuration stuff
	einfo "Building default configuration ..."
	insinto "${MY_SYSCONFDIR#${EPREFIX}}"
	doins "${FILESDIR}"/mysqlaccess.conf
	cp "${FILESDIR}/my.cnf-10.2" "${TMPDIR}/my.cnf" || die
	eprefixify "${TMPDIR}/my.cnf"
	doins "${TMPDIR}/my.cnf"
	insinto "${MY_SYSCONFDIR#${EPREFIX}}/mariadb.d"
	cp "${FILESDIR}/my.cnf.distro-client" "${TMPDIR}/50-distro-client.cnf" || die
	eprefixify "${TMPDIR}/50-distro-client.cnf"
	doins "${TMPDIR}/50-distro-client.cnf"

	if use server ; then
		mycnf_src="my.cnf.distro-server"
		sed -e "s!@DATADIR@!${MY_DATADIR}!g" \
			"${FILESDIR}/${mycnf_src}" \
			> "${TMPDIR}/my.cnf.ok" || die
		if use prefix ; then
			sed -i -r -e '/^user[[:space:]]*=[[:space:]]*mysql$/d' \
				"${TMPDIR}/my.cnf.ok" || die
		fi
		if use latin1 ; then
			sed -i \
				-e "/character-set/s|utf8|latin1|g" \
				"${TMPDIR}/my.cnf.ok" || die
		fi
		eprefixify "${TMPDIR}/my.cnf.ok"
		newins "${TMPDIR}/my.cnf.ok" 50-distro-server.cnf
	fi
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
