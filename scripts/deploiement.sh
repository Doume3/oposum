#! /bin/bash
#APPEL DU SCRIPT AVEC LOGIN & SITE

ERR_ARGS=85

if [ $# -ne 2 ]  # Correct number of arguments passed to script?
then
  echo "Usage: `basename $0` login site"
  exit $ERR_ARGS
fi

login=$1;
site=$2;
#+------------------------+
#|		APPLICATIONS        |
#+------------------------+
$laptop>
scp -r -p Serveur/ $login@access.grid5000.fr:$site


#+------------------------+
#|		Connexion           |
#+------------------------+
#$laptop>

#ssh $login@access.grid5000.fr
#ssh $site

#+------------------------+
#|		Initial setup		    |
#+------------------------+
#$frontend>

#git clone https://github.com/grid5000/xp5k-openstack.git
cd xp5k-openstack;
source setup_env.sh;
#gem install bundler
#bundle install

#+------------------------+
#|		Prepare deployment  |
#+------------------------+

: '
echo "site           'rennes'
walltime        '4:00:00'
scenario        'liberty_starter_kit'
public_key      \"#{ENV['HOME']}/.ssh/id_rsa.pub\"
gateway         \"#{ENV['USER']}@frontend.#{self[:site]}.grid5000.fr\"" >> xp.conf;
'


#+------------------------+
#|		Start deployment    |
#+------------------------+
screen -c shellScreen;


#+------------------------+
#|		Import clef RSA			|
#+------------------------+
VAR=rake roles:show | grep "controller" | grep -o -E "[^: ]*\.grid5000\.fr";
cat ~/.ssh/id_rsa.pub | ssh root@$VAR "source openstack-openrc.sh && nova keypair-add --pub_key - demo";


#+------------------------+
#|	Launch a VM instance	|
#+------------------------+
#./VM_launcher.sh;


# --- Stop the experiment
#rake grid5000:clean;
