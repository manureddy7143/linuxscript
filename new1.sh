function unsupported {
	echo "Unsupported operating system."
	exit 1	
}
function install_rpm {
	if ! hash curl > /dev/null 2>&1; then
		echo "* Installing curl"
		yum -q -y install curl
	fi

	echo "* Installing relay agent-rpm"
}

function install_deb {
	export DEBIAN_FRONTEND=noninteractive

	if ! hash curl > /dev/null 2>&1; then
		echo "* Installing curl"
		apt-get -qq -y install curl < /dev/null
	fi

	echo "* Installing relay agent-deb"


}
echo "* Detecting operating system"

ARCH=$(uname -m)
if [[ ! $ARCH = *86 ]] && [ ! $ARCH = "x86_64" ] && [ ! $ARCH = "s390x" ]; then
	unsupported
fi

if [ $ARCH = "s390x" ]; then
	echo "------------"
	echo "WARNING: A Docker container is the only officially supported platform on s390x"
	echo "------------"
fi

if [ -f /etc/debian_version ]; then
	if [ -f /etc/lsb-release ]; then
		. /etc/lsb-release
		DISTRO=$DISTRIB_ID
		VERSION=${DISTRIB_RELEASE%%.*}
	else
		DISTRO="Debian"
		VERSION=$(cat /etc/debian_version | cut -d'.' -f1)
	fi

	case "$DISTRO" in

		"Ubuntu")
			if [ $VERSION -ge 10 ]; then
				install_deb
			else
				unsupported
			fi
			;;

		"LinuxMint")
			if [ $VERSION -ge 9 ]; then
				install_deb
			else
				unsupported
			fi
			;;

		"Debian")
			if [ $VERSION -ge 6 ]; then
				install_deb
			elif [[ $VERSION == *sid* ]]; then
				install_deb
			else
				unsupported
			fi
			;;

		*)
			unsupported
			;;

	esac


elif [ -f /etc/system-release-cpe ]; then
	DISTRO=$(cat /etc/system-release-cpe | cut -d':' -f3)

	# New Amazon Linux 2 distro
	if [[ -f /etc/image-id ]]; then
		AMZ_AMI_VERSION=$(cat /etc/image-id | grep 'image_name' | cut -d"=" -f2 | tr -d "\"")
	fi

	if [[ "${DISTRO}" == "o" ]] && [[ ${AMZ_AMI_VERSION} = *"amzn2"* ]]; then
		DISTRO=$(cat /etc/system-release-cpe | cut -d':' -f4)
	fi

	VERSION=$(cat /etc/system-release-cpe | cut -d':' -f5 | cut -d'.' -f1 | sed 's/[^0-9]*//g')

	case "$DISTRO" in

		"oracle" | "centos" | "redhat")
			if [ $VERSION -ge 6 ]; then
				install_rpm
			else
				unsupported
			fi
			;;

		"amazon")
			install_rpm
			;;

		"fedoraproject")
			if [ $VERSION -ge 13 ]; then
				install_rpm
			else
				unsupported
			fi
			;;

		*)
			unsupported
			;;

	esac

else
	unsupported
fi

