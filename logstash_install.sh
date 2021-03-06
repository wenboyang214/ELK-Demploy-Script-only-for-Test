
# only for Test in install logstash in ARM Template
# Thanks for the  original author


# Go as root 
if [ "${UID}" -ne 0 ];
then
    echo "You must be root to run this program." >&2
    exit 3
fi
# def 
help()
{
    echo ""
    echo ""
	echo "This script installs Logstash 2.2.4 on Ubuntu, and configures it to be used with user plugins/configurations"
	echo "Parameters:"
	echo "p - The logstash package url to use. Currently tested to work on Logstash version 2.2.4"
	echo "e - The encoded configuration string."
	echo ""
	echo ""
	echo ""
}

log()
{
	echo "$1"
	logger "$1"
}

#Loop through options passed  simply set configuration as Parameter
while getopts e: optname; do
    log "Option $optname set with value ${OPTARG}"
  case $optname in
    e)  #set the encoded configuration string
	  log "Setting the encoded configuration string"
      CONF_FILE_ENCODED_STRING=${OPTARG}
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

# Install Java
echo "begin install"
log "begin install"
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get -y update  > /dev/null
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -y install oracle-java8-installer > /dev/null
echo "java8 has been installed"
log "java8 has been installed"

# Install Logstash
# The Logstash package is available from the same repository as Elasticsearch . Install the public  key.
# Create the logstash source list
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "begin to install logstash"
logger "begin to install logstash"
echo 'deb http://packages.elastic.co/logstash/2.2/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash-2.2.x.list

sudo apt-get update

sudo apt-get install logstash

# Install User Configuration from encoded string 
# The configuration file is in /etc/logstash/logstash.conf
log "Decoding configuration string"
log "$CONF_FILE_ENCODED_STRING"
echo $CONF_FILE_ENCODED_STRING > logstash.conf.encoded
DECODED_STRING=$(base64 -d logstash.conf.encoded)
log "$DECODED_STRING"
echo $DECODED_STRING > ~/logstash.conf

# Install logstash_plugin for Azure such logstash-input-azureblob | logstash-input-azureeventhub
# Do it latter

#log "Installing user configuration file"
log "Installing user configuration named logstash.conf"
sudo \cp -f ~/logstash.conf /etc/logstash/conf.d/

# Configure Start
log "Configure start up service"
sudo update-rc.d logstash defaults 96 9
sudo service logstash start
