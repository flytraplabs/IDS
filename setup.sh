#!/usr/bin/env bash
#
#                                          ZI
#                                         7$I
#                                        $7OI
#                                        $7MI
#                                        $$DZ
#                                        $$D
#                                        M$I
#                                        M8
#                                ??$ $$  $$
#                              D+O$77O$ $$$M              MN MM M
#                               ++D$77M$$$$$             MZ7+++$7+N
#                    D M        +I$N$7Z$$$$$            8????+++++$ON
#                 $+Z$D$?7    7$?++N$$M7$$$Z           ?II777II???++NM
#               +??++N$$77I    MI?+Z8$OM7$$          MN77$$$$$$$777IIN
#             M?8III??++$77I   $Z8MMO  MI7$           7$$$$$$$$$$$$$$7
#             Z77$$$7I?++877O  DM7I ++ M?I7      D??I7$$$$$$$$$$$$$$7
#          D  D$$$$$$$I?++8D    $$7 ?+ M??        ++    ZZMM$$   $7M
#      M?N$$$     $N$$MI??      O$$ I?MD++  MM MMMN      Z$M N      M M
#    M?$$D$$$$$$M$DI777   ??++   Z$$7I?7+  ++???N7?    $$$       M7I?++D7M
#   N+7$M$$$$$MZ8I77$$$N    $II  $$$M77?+ M??I7777N$MD$$    D   O$$7I??++$O
#   +I7Z$$$$$$ $I77$$$$$$$O   O$  M$ $$OIZI77$$$$$$M$$$   $$$$Z$N$$$$7I?++$N
#   8MO7$$$$M  ZI77Z    $$N$$M M$ $$ $$O$ON$$$$$  $M$$ $$$NNO    $$$$$7I+++8
#  MZII7$$$N  M$I77       IINZ$  $M$$$$M$$ZM$$N   $$$$$$$$Z$$$   N$$$$7I+++M$
#   MN$7$$$              M77ZO$$  $M$M$$$$ $D$   $$O$$$$8M$$$O    $$$$7I?++$$
#   MNO$$$8               D77$$$$$ O$M$D$ M$$Z  M$$$O $  $M        $$$7I?++NZ
#      M$8                 Z$$$NNMMNNNNNN $M$   $$$ O$  $$           $7MIM+$M
#                MNNNNNNNNNNM$NNNNNNNNNNNMNNNNNNNNNNNNMMMM              ??
#       MMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN$NNNNNNNNM
#                            MNNNNNNNNNNNNNMMMM         MMMMMM MMMMMMNNNM
#
# flytrap labs 2013
# IDS deployment script
#




function usage
{
    echo "usage: ./setup.sh --install [server | sensor]"
}


function debian_server_install
{
	echo "$COL_GREEN Enter a password for your redis instance. This will be the same password you will use in your shipper.conf. $COL_RESET"
	read -s -p "Password: " password

	apt-get install default-jdk git redis-server apache2
	wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.5.deb
	dpkg -i elasticsearch-0.90.5.deb
	service elasticsearch start
	sed -i 's/# network.bind_host: 192.168.0.1/network.bind_host 0.0.0.0/g' /usr/local/elasticsearch/config/elasticsearch.yml
	/etc/init.d/elasticsearch restart
	sed -i '/bind 127.0.0.1/d' /etc/redis/redis.conf
	echo "requirepass $PASSWORD" >> /etc/redis/redis.conf
	/etc/init.d/redis-server restart
	mkdir -p /opt/logstash
	wget https://download.elasticsearch.org/logstash/logstash/logstash-1.2.1-flatjar.jar -O /opt/logstash/logstash.jar
	wget https://raw.github.com/flytraplabs/IDS/master/indexer.conf -O /opt/logstash/indexer.conf
	sed -i "s/DEFAULT_PASSWORD/$PASSWORD/g" /opt/logstash/indexer.conf
	wget https://raw.github.com/flytraplabs/IDS/master/logstash-init.sh -O /etc/init.d/logstash-init.sh
	chmod +x /etc/init.d/logstash-init.sh
	mkdir -p /var/lock/subsys
	update-rc.d logstash-init.sh defaults
	initctl reload-configuration
	/etc/init.d/logstash-init.sh start
	wget https://download.elasticsearch.org/kibana/kibana/kibana-3.0.0milestone4.tar.gz
	tar -z -xf kibana-3.0.0milestone4.tar.gz
	mv kibana-3.0.0milestone4 kibana
	mv kibana /opt/
	wget https://raw.github.com/flytraplabs/IDS/master/000-kibana -O /etc/apache2/sites-available/000-kibana
	cd /etc/apache2/sites-enabled
	ln -s /etc/apache2/sites-available/000-kibana
	rm -rf /etc/apache2/sites-enabled/000-default
	apache2ctl restart
}

function install_server
{

	echo $1

	if [ "$1" == "Debian" ]; then
		debian_server_install
	elif [ "$1" == "Ubuntu" ]; then
		debian_server_install
	elif [ "$1" == "Red Hat" ]; then
		debian_server_install
	elif [ "$1" == "Fedora" ]; then
		debian_server_install
	elif [ "$1" == "CentOS" ]; then
		debian_server_install
	fi
}

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

# OS detection
if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    DISTRO=$DISTRIB_ID
elif [ -f /etc/debian_version ]; then
    DISTRO="Debian"
elif [ -f /etc/redhat-release ]; then
    DISTRO="Red Hat"
elif [-f /etc/fedora-release ]; then
	DISTRO="Fedora"
elif [ -f /etc/centos-release ]; then
	DISTRO="CentOS"
else
	echo "$COL_RED [!] $COL_RESET distro not supported"
	exit
fi

#parse args
INSTALL_TYPE=""
while [ "$1" != "" ]; do
    case $1 in
        -i | --install )           shift
                                INSTALL_TYPE=$1
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ "$INSTALL_TYPE" = "" ]; then
	usage
	exit
elif [ "$INSTALL_TYPE" = "server" ]; then
	install_server $DISTRO
elif [ "$INSTALL_TYPE" = "sensor" ]; then
	install_server $DISTRO
fi
