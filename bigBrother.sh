#!/bin/bash
# commande test -e existence d'un fichier
ip=$(ip r | grep "default" |cut -d "s" -f 2 |  grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | sort -u)

echo -e "\n---------== BigBrother Monitoring 0.0.2==---------\n"
echo -e "\t   IP : $ip\n"
echo -e "\n--------------------------------------------------\n\n"


#Fonction de gestion des erreurs

Erreur()
{
  echo -e "\n+--------------------[/+\]----------------------+\n\n"
  echo -e   "|                   Erreur                      |"
  echo -e "\n+-----------------------------------------------+\n\n"
  exit 2
}

#Verification du lancement en root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être lancé avec les droits admin !" 1>&2
   exit 1
fi

repeter=-1
attente=2							#Indique le temps d'attente entre chaque clollecte de données
delay=10 							#Indique les delaie de mise ajour (Par defaut 300s = 5 minutes)
let check=$(($delay/$attente)) 	#Permet de determiner combien de donner il faut envoyer pour que le delai soit ecoule
host="192.168.44.13"
master="http://$host:8080" 			#L'adresse du serveur Monitoring

#repeter=10
#attente=5

#Verification des dependances

#Verification proxy

export https_proxy="http://proxy.iut-orsay.fr:3128"
export http_proxy="http://proxy.iut-orsay.fr:3128"	
export no_proxy="localhost,127.0.0.1,192.168.44.13"

#Mise à jour de l'heure
if [ "$(cat /etc/systemd/timesyncd.conf | grep "NTP=ntp.u-psud.fr"| wc -l )" -ne 1 ]
then
	echo "  - Date corompue"
	echo "NTP=ntp.u-psud.fr" >> /etc/systemd/timesyncd.conf
	systemctl restart systemd-timesyncd
	echo "  - Date mise a jour"
fi
echo -e "  - Date\t\t[ok]"

#Verification de l'integrite des fichiers
if [ "$(ls -l /opt | grep  bigBrother | wc -l )" -eq 0 ] 
then
    echo "  - Creation repertoire dans /opt/bigBrother"
    mkdir /opt/bigBrother
    mkdir /opt/bigBrother/tmp
    chmod 755 /opt/bigBrother/tmp
    chmod 755 /opt/bigBrother
    echo -e "  - Repertoire\t\t[ok]"
fi


if [ "$(ls -l /opt/bigBrother | grep utils | wc -l )" -eq 0 ]
then
   echo -e " - Téléchargement des paramètres de sécurité"
   mkdir /opt/bigBrother/utils
   wget -P /opt/bigBrother/utils $master/utils/ca.crt
   wget -P /opt/bigBrother/utils $master/utils/client.crt
   wget -P /opt/bigBrother/utils $master/utils/client.key   
   echo -e " - Paramètres de sécurité : [ok]"	

fi

 #Creation du fichier de maj
if [ "$(ls -l /opt/bigBrother/ | grep current_update | wc -l )" -eq 0 ] 
then
    echo -e "  - Recuperation des fichiers de mise a jour\n"
    wget -P /opt/bigBrother $master/update/bigBrother-software/update
    mv /opt/bigBrother/update /opt/bigBrother/current_update
    echo -e "  - Fichier Maj\t\t[ok]"
fi
echo -e "  - Integrite\t\t[ok]"

#Installation des paquets utile : 
if [ "$(dpkg -l | grep "sysstat" | wc -l)" -eq 0 ]
then
	echo "  - Iostat non installe"
	apt-get -y install sysstat && 
	echo "  - Iostat installe"
fi

echo -e "  - Iostat\t\t[ok]"
if [ "$(dpkg -l | grep "mosquitto-clients" | wc -l)" -eq 0 ]
then
	echo "  - Mosquitto-clients non installe"
	apt-get install  -y  mosquitto-clients
	echo "  - Mosquitto-clients installe"
fi
echo -e "  - Mosquitto-clients\t[ok]"


#Mise en place du script pour qu'il ce lance au démarage
if [ "$(ls /etc/init.d | grep bigBrother-soft | wc -l)" -eq 0 ]
then
    echo "  - Mise de bigBrother au démarage"
    wget -P /etc/init.d $master/update/bigBrother-software/"$(cat /opt/bigBrother/current_update | tail -1 )"
    chmod 711 /etc/init.d/"$(cat /opt/bigBrother/current_update | tail -1 )"
	mv /etc/init.d/"$(cat /opt/bigBrother/current_update | tail -1 )" /etc/init.d/bigBrother-soft

	echo -e "  - BigBrother seras lancé au démarage\t[ok]"
fi



#Recuperation du script
if [ "$(ls /opt/bigBrother | grep bigBrother-soft | wc -l)" -eq 0 ]
then
    echo "  - Installation de bigBrother"
    wget -P /opt/bigBrother $master/update/bigBrother-software/"$(cat /opt/bigBrother/current_update | tail -1 )"
    chmod 711 /opt/bigBrother/"$(cat /opt/bigBrother/current_update | tail -1 )"
    mv /opt/bigBrother/"$(cat /opt/bigBrother/current_update | tail -1 )" /opt/bigBrother/bigBrother-soft
	


	if [ $(echo `pwd`) != "/opt/bigBrother" ]
	then
		echo "Le programme vas etre lance depuis le bon répertoire"
		cd /opt/bigBrother
		exec ./bigBrother-soft
		exit 1
	fi

	echo -e "  - BigBrother Pret\t[ok]"
fi



echo -e "\n--------------------------------------------------\n\n"
#On verifie que il n'y a q'un seul bigBrother d'ouvert

let i=0

while  [ $i -ne $repeter ]
do
	
	#Chek des updates ( one ne fait le chack que toutes les 5 minutes par defaut.)
	echo -e "I : $i  check $(($i%$check))\n"
	if [ $(($i%$check)) -eq 0 ]
	then
		
		echo -e "\n\t  ---- Verification des mises a jour  $i ---"
		wget -P /opt/bigBrother/ $master/update/bigBrother-software/update

		if [ "$(sudo cat /opt/bigBrother/current_update | tail -1 )" != "$(sudo cat /opt/bigBrother/update | tail -1 )" ]
		then
			echo -e "\n+--------------------[ + ]----------------------+"
  			echo -e   "|              Mise a jour detectee             |"
  			echo -e "\n+-----------------------------------------------+\n\n"

			cat /opt/bigBrother/update > /opt/bigBrother/current_update
			rm /opt/bigBrother/update
			echo -e "\n  - Chargement de la mise a jour"
			echo -e "\n  - Installation du logiciel dans opt"
			wget -P /opt/bigBrother $master/update/bigBrother-software/$(cat /opt/bigBrother/current_update | tail -1 ) 1>/dev/null 2>/dev/null
			chmod 777 /opt/bigBrother/$(cat /opt/bigBrother/current_update | tail -1 )
			rm /opt/bigBrother/bigBrother-soft
			mv /opt/bigBrother/$(cat /opt/bigBrother/current_update | tail -1 ) /opt/bigBrother/bigBrother-soft

			echo -e "\n  - Installation mise a jour du script de démarage"
			wget -P /etc/init.d $master/update/bigBrother-software/"$(cat /opt/bigBrother/current_update | tail -1 )"
    		chmod 711 /etc/init.d/"$(cat /opt/bigBrother/current_update | tail -1 )"
			rm /etc/init.d/bigBrother-soft
			mv /etc/init.d/"$(cat /opt/bigBrother/current_update | tail -1 )" /etc/init.d/bigBrother-soft

			echo -e "  - PidBrother : $brotherPid\n"
			#nohup ./bigBrother-soft &
			echo "  - Demarage nouvelle version"
			cd /opt/bigBrother/
			#nohup.out >>old_bigBrother.log
			#nohup ./bigBrother-soft 1>/dev/null 2>/dev/null & 
			echo -e "  - BigBrother\t\t[ok]"
			echo -e "  - Maj \t\t[ok]\n\n"
			echo "  - Restart"
			cd /opt/bigBrother
			exec ./bigBrother-soft
			exit 1
		fi
		rm /opt/bigBrother/update

	fi

	#Recuperation des valeurs

	diskUsage="$(df | head -n 2 | grep "/" | tr -s " " | cut -d " " -f 5 | cut -d "%" -f 1)"
	memTotal="$(cat /proc/meminfo  | grep "MemTotal" | tr -s " " | cut -d " " -f 2)"
	memUse="$(free | grep "Mem" | tr -s " " | cut -d " " -f 3)"
	pourcentMem="$(($memUse*100/$memTotal))"
	tempCPU="$(cat /sys/class/thermal/thermal_zone0/temp)"
	procUsage=$(ps -aeo %cpu | grep -v "%CPU" | awk '{somme+=$1} END {print somme}')
	reading=$(iostat | grep "mmcblk0" | tr -s " " | cut -d " " -f 3)
	writing=$(iostat | grep "mmcblk0" | tr -s " " | cut -d " " -f 4)
	nbUser=$(who | wc -l)

	#Calcule du uptime en seconde
	bootTime="$(date --date="$(uptime -s)" +%s)"
	current="$(date +%s)"
	let upTime=$(($current-$bootTime))

	

	#Affichage local
	echo -e "\tMesure n°$i\n"
	echo "Uptime : $upDay day(s) and $upHour:$upMin:$upSec"
	echo -e "Utilisateurs en ligne : $nbUser\n"
	echo "Stockage utilise : $diskUsage%"
	echo "Lecture $reading kbs/sec"
	echo -e "Ecriture $writing kbs/sec\n"
	echo "Utilisation memoire : $pourcentMem%"
	echo "Utilisation CPU : $procUsage%"
	let tempHuman=$(($tempCPU/1000))
	echo -e "Temperature CPU : $tempHuman°c\n"
	
	#Envoie des données

	mosquitto_pub --cafile /opt/bigBrother/utils/ca.crt --cert /opt/bigBrother/utils/client.crt --key /opt/bigBrother/utils/client.key -d -h $host -p 1883 -t 'test/topic' -m "IP $ip:UP $upTime:USERS $nbUser:DISKUSE $diskUsage:READ $reading:WRITE $writing:MEMUSE $pourcentMem:CPUUSE $procUsage:TEMPCPU $tempHuman" -q 2
	echo -e "\nDonne envoye \n\n"

	i=$((i+1))
	sleep $attente
done
