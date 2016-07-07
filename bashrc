
penvtag=sjhw
version=2.1

if [[ $MYSTARTUPINCLUDED != "$version" || $PS1 != "" ]] ; then

	export MYSTARTUPINCLUDED=$version
	althost="$(cat ~/.althost 2>/dev/null | awk 'NR == 1 { print toupper($0) }' )"
	altcol="$(cat ~/.althost 2>/dev/null | awk 'NR == 2 { print toupper($0) }' )"
	[[ $altcol == "" ]] && altcol=clear
	hname=$( (hostname;grep . ~/.hostname 2>/dev/null) | tail -1 )

	# use colours ?

	if [[ ! -f ~/.nocolor ]] ; then

	       CTAG_RED="\033[01;41m\033[01;37m"
	     CTAG_GREEN="\033[01;42m\033[01;37m"
	    CTAG_ORANGE="\033[01;43m"
	      CTAG_BLUE="\033[01;44m\033[01;37m"
	      CTAG_CYAN="\033[01;46m"
	    CTAG_YELLOW="\033[01;103m"
	      CTAG_PINK="\033[01;101m\033[01;37m"
	    CTAG_LGREEN="\033[01;102m"
	    CTAG_PURPLE="\033[01;45m\033[01;37m"
	    TTAG_PURPLE="\033[01;35m"
	       TTAG_RED="\033[01;31m"
	     CTAG_CLEAR="\033[01;00m"

	    RAINBOW="${CTAG_RED} ${CTAG_GREEN} ${CTAG_ORANGE} ${CTAG_BLUE} ${CTAG_YELLOW} ${CTAG_CYAN} ${CTAG_PURPLE} ${CTAG_PINK} ${CTAG_LGREEN} ${CTAG_CLEAR}"

		export LS_COLORS="ex=01;90:ln=01;91"

	fi

    # initial message

	if [[ -t 1 ]] ; then
		printf "\n$penvtag($version)\n"
		[[ $althost != "CLIENT" ]] && printf "${RAINBOW}"
		printf "\n"
	fi

	# shell options

	shopt -s histappend
	shopt -s checkwinsize
	set -o vi
	unset command_not_found_handle
	
	# variables

	ALTHOST="$( echo $althost | awk '/./ { print " '$( eval 'echo $CTAG_'$altcol )${althost}${CTAG_CLEAR}'" }')"
	export PATH=$PATH:/usr/sbin:/sbin:$HOME/bin
	export PROMPT_COMMAND='history -a'
	export HISTCONTROL=""
	export HISTTIMEFORMAT="%F %T  "
	export HISTSIZE=4000
	export LS_COLORS="ex=01;90:ln=01;91"
	export EDITOR=vi

	# prompt

	[[ $althost != "CLIENT" ]] && RAINBOW=""
    PS1="${RAINBOW}\n\t ${USER}@${hname}${ALTHOST} \${PWD} $TTAG_RED\$(trim0 \$?)$TTAG_PURPLE\$( git log -1 --pretty=format:%h 2> /dev/null )${CTAG_CLEAR}\n$ "
	
	# functions

	function trim0 () { echo "$1 "|sed 's/^0 //' ; }
	function null () { cat > /dev/null; }
	function fld () { awk '{ print $'$1'; }'; }
	function xml() { tidy -xml -indent $1 ; }
	function hh () { history | grep "$1"; }
	function h1 () { history | grep "$1" | tail -10 ; }
	function h2 () { history | grep "$1" | tail -20 ; }
	function h3 () { history | grep "$1" | tail -30 ; }
	function h4 () { history | grep "$1" | tail -40 ; }
	function funcs () { if [[ $1 == "" ]] ; then declare -F | fld 3 | grep -v "^_" ; else typeset -f $@ ; fi }
	function localrm () { ( echo; echo "DO NOT USE 'rm' PLEASE SHRED"; echo ) 1>&2 ; }
	
	# vim config setup 

	( (
		echo -e "\" DO NOT EDIT - updated automaticlly\n\"               from .bashrc\n\nset number\nset hlsearch"
		echo -e "set tabstop=4\nset shiftwidth=4\nset modeline\nsyntax on"
	) > $HOME/.vimrc ) 2>/dev/null
	
	# aliases

	alias rm=localrm




	
	# default b/exrc settings

	echo -e "set number\nset hlsearch\nset tabstop=4\nset shiftwidth=4" > $HOME/.exrc

	#
	#	FUNCTIONS AND ALIASES
	#

    alias ls='ls --color=auto'
	alias vag=vagrant

	alias hl=hostlookup
	function hostlookup () {
		# not much use without some server grouops and definitions setup
		(
		tmpxx=""
		for h in "$@" ; do
			if [[ $h = appint ]] ; then
				tmpxx="$tmpxx $( echo site{2,1}app00{1,2} )"
			elif [[ $h = appauth ]] ; then
				tmpxx="$tmpxx $( echo site{2,1}app00{3..6} )"
			elif [[ $h = apprep ]] ; then
				tmpxx="$tmpxx $( echo site{2,1}app00{7,8} )"
			elif [[ $h = webin ]] ; then
				tmpxx="$tmpxx $( echo site{1,2}web00{1,2,3} )"
			elif [[ $h = webout ]] ; then
				tmpxx="$tmpxx $( echo site{1,2}web00{4,5,6} )"
			else 
				tmpxx="$tmpxx $h"
			fi
		done
		echo $( for h in $tmpxx ; do serv_alias | awk -F\| -v HOST=$h '$1 == HOST { print $2 ; i=1 ; exit } END { if(i!=1) {print HOST ;} }' ; done )

		)

	}	

	function tall () {
		(
			export SSHPARAM="-t"
			rall "$@"
		)
	}

	function rall () {
		execute="$1"
		shift
		tmp="$( hostlookup "$@" )"
		echo $tmp
		for h in $tmp
		do	
			localssh __EXPAND__ $h $SSHPARAM "$execute"
			sleep 0.2
		done
	}

	alias althost=althost_func
	function althost_func {
		if [[ $1 == "set" ]]; then
			shift
			( for n in $@ ; do echo $n ; done ; ) > ~/.althost
			if [[ $? = 0 ]] ; then
				reload
			fi
		elif [[ $1 == "clear" ]]; then
			\rm ~/.althost
			if [[ $? == 0 ]] ; then
				reload
			fi
		else
			echo "Usage: althost set|clear TAG COLOR" 1>&2
		fi
	}

	function null () { cat > /dev/null; }
	
	function fld () { awk '{ print $'$1'; }'; }
	
	function localssh () {
		tagname=""
		if [[ $1 == "__EXPAND__" ]] ; then
			shift;
			tagname=$1
			sname="$(hostlookup $1)" ; shift
		else
			sname=$1; shift
		fi

		gc=$( serv_alias | awk -F\| '$2 == "'$sname'" && $3 ~ /^GCLOUD=/ { print substr($3,8) ; exit }' )
		if [[ $gc == "" ]] ; then
			if [[ $tagname != "" ]] ; then
				echo -e "\n$tagname ==> ssh $sname $@ \n"; 
			fi
			ssh $sname $@;
		else	
			unxname="$( echo "$gc" | awk -F: 'NF > 2 { print $3 "@" }' )"  
			echo
			echo "$tagname ==> "'gcloud compute --project '$( echo "$gc" | awk -F: '{ print $1 }' )' ssh --zone '$( echo "$gc" | awk -F: '{ print $2 }' )' '$unxname$sname''	
			echo
			gcloud compute --project "$( echo "$gc" | awk -F: '{ print $1 }' )" ssh --zone "$( echo "$gc" | awk -F: '{ print $2 }' )" "$unxname$sname" 
		fi
	}
	
	function xml() { tidy -xml -indent $1 ; }

	function proxy()
	{
		if [[ $1 = "off" ]] ; then
			export http_proxy=""
			echo export http_proxy=""
			export https_proxy=""
			echo export https_proxy=""
		fi
		if [[ $1 = "1" || $1 = "on" ]] ; then
			export http_proxy=http://10.33.197.21:8080
			echo export http_proxy=http://10.33.197.21:8080
			export https_proxy=http://10.33.197.21:8080
			echo export https_proxy=http://10.33.197.21:8080
		fi

	}

	alias rm=localrm
	function localrm () { ( echo;echo "DO NOT USE 'rm' PLEASE SHRED"; echo ; ) 1>&2 ; }

	function mycdir () {
		tcd="XX_NO_VALID_DIR_XX"
		for x in $@ ; do 
			if [[ -d "$x" ]] ; then tcd="$x" ; break ; fi
		done
		if [[ $tcd == "XX_NO_VALID_DIR_XX" ]] ; then
			echo "No Valid Local directory: $@" 1>&2
		else
			cd $tcd
		fi
	}

	function ram () {
		if [[ -L $HOME/ram || -d $HOME/ram ]] ; then
			cd $HOME/ram;
		else
			mycdir /ramdisk/$penvtag /ramdisk;
		fi
	}

	function dtom () { mycdir /var/lib/tomcat6/webapps; }
	function dtcl () { mycdir /etc/tomcat6/Catalina/localhost; }
	function dcron () { mycdir /etc/cron.d/; }
	function gclone () { echo "git clone ssh://git/home/git/$1 $2 $3 $4" ; git clone ssh://git/home/git/$1 $2 $3 $4; }

	function tailwrapper () {
		cmd=$1
		echo "$cmd"
		if [[ $2 == "" ]] ; then
			$cmd
		else
			localssh -t $(hostlookup $2) "$cmd" | awk '/^.$/ || /^$/ {print;next} { print strftime("%T ") $0 }'
		fi
	}
	function tail78 () {
		# useless example as nemonic
		tailwrapper "tail -F /var/log/XXX/reporting.log /var/log/XXX/proxy.log /var/log/XXX/app.log " $1
	}
		
	function tailconnect () {
		sudo tail -F $(find /var/lib/mysql -name "*.log" 2>/dev/null|grep std_log|grep -v old)| grep -w Connect
	}

	function logmys {

		LOG=$HOME/log/logmys.log
		mkdir ~/log 2>/dev/null
		( echo ; date ; echo logmys "$@" ; echo ) >> $LOG
		(
			mys "$@" -tv 2>&1
		) | tee -a  $LOG

	}

	function dataset () {
		cat $HOME/.bashrc | awk '
			/^==begin/ && $2 == "'$1'" { started = "yes";next }
			started != "yes" { next }
			/^==/ { exit 0 }
			{ print } '
	} 

	function dls {
		pattern=.
		[[ $1 != "" ]] && pattern="$1"
		( for n in $( dataset alldomain | sed 's/#.*//' | fld 1 ) ; do echo $n; done) | sort -u | grep "$pattern"
	}

	function sls {
		pattern=.
		[[ $1 != "" ]] && pattern="$1"
		( for n in $( dataset alladdress | sed 's/#.*//' | fld 1 ) ; do echo $n; done) | sort -u | grep "$pattern"
	}

	function serv_alias {
		dataset allservers |
			awk '{ split($1,x,","); for(y in x) { print x[y] "|" $2 "@" $3 "|" $4 } }'
	}
	serv_alias | awk -F\| '{ print "alias " $1 "=\"localssh __EXPAND__ " $1 "\";" }' > /tmp/$penvtag.$$
	. /tmp/$penvtag.$$
	\rm /tmp/$penvtag.$$

	function vigpg() {
	
		EFILE=$1
		export TMPDIR="/tmp"
		[ -e "$HOME/tmp" ] && export  TMPDIR="$HOME/tmp"
		[ -e /ramdisk ] && export  TMPDIR="/ramdisk/$penvtag"
		TFILE=$TMPDIR/vigpg.tmp.$$
		touch $TFILE ; chmod 600 $TFILE
		echo "Using $TFILE as tmpfile"
		if [ ! -e "$TFILE" ]  ; then
  			echo "Failed to create tempfile, bailing."
		else
			if [ -e $EFILE ] ; then
  				gpg -d < $EFILE > $TFILE
			else
  				touch $EFILE
			fi
			
			vi $TFILE
			
			cp $EFILE $EFILE.bak
			gpg -e -a < $TFILE > $TFILE.gpg
			[[ $? != 0 ]] &&  echo Error encrypting.  Backup saved as $EFILE.bak.
			if [[ -s $TFILE.gpg ]] ; then
				cat $TFILE.gpg > $EFILE
			else 
				shred -u $EFILE.bak
			fi
			shred -u $TFILE $TFILE.gpg
		fi
		
	}


	function mysqlgrep() {
		if [[ $1 == "" ]] ; then 
			find ~mysql -name std_log 2>/dev/null | awk '{ print "sudo tail -F " $0 "/*.log | mysqlgrep" }'
		else
			awk '
			BEGIN { FS="\t"; }
			{
        			if( $1 == "" ) { act=$3 } else { act=$2 }
        			trans = substr(act,1,match(act," ")-1);
        			action = substr(act,match(act," ")+1);
			}
			action == "Connect" && /'"$1"'/ { d[trans]=1; print; next }
			action == "Init DB" && /'"$1"'/ { d[trans]=1; print; next }
			action == "Init DB" { delete d[trans]; next }
			action == "Quit" { if( d[trans]==1 ) { delete d[trans]; print; } next }
			/'"$1"'/ { print; next }
			d[trans] == 1 { print }
			'
		fi
	}
	
	function nls() {
		for domain in $(sls) ; do
			dig $domain | grep -A 1 "ANSWER SECTION" | awk '/IN/ { printf("%40s %s (%s)\n",$1,$NF,$2); }'
		done
	}

	function funcs {
		if [[ $1 == "" ]] ; then
			declare -F | fld 3 | grep -v "^_"
		else 
			typeset -f $@
		fi
	}

	alias scp=localscp
	function localscp {

		eval \\scp $(

			( echo "$@" ; serv_alias ) | awk -F\| '
				NR == 1 { params=$0 ; next }
				{ serv[$1]=$2 }
				END {
					split(params,p,/[ \t]+/)
					for( i in p ) {
						if(  match(p[i],/^[a-zA-Z][a-zA-Z0-9\.]*:/) ) {
							if( serv[ substr(p[i],1,RLENGTH-1) ] ) {
								p[i] = serv[ substr(p[i],1,RLENGTH-1) ] substr(p[i],RLENGTH)
							}
						}
						printf(" %s",p[i])
					}
				}'
		)
	}

	for f in "$HOME/google-cloud-sdk/completion.bash.inc" "$HOME/google-cloud-sdk/path.bash.inc"
	do
		if [[ -f  $f ]] ; then
			source $f
		fi
	done

	#gcloud 
	function setlemp () {
        	gcloud config set project top-athlete-87816
        	gcloud config set compute/zone us-east1-b
        	gcloud config list | awk '$1 == "zone" || $1 == "project" { print }'
	} 

	function setcore () {
        	gcloud config set compute/zone europe-west1-d
        	gcloud config set project coretest-1187
        	gcloud config list | awk '$1 == "zone" || $1 == "project" { print }'
	} 

	function allservers () {
			dataset allservers;
	}

	alias instances="gcloud compute instances"

	alias rvcore="ssh -A -t qm@twig.qmonkey.co.uk ssh -A core@192.168.1.201"
	alias rhomer="ssh -A -t qm@twig.qmonkey.co.uk ssh -A vagrant@192.168.1.199"

fi

#
#	Now outside of the run once section.
#	Here we add in things which should be defined every time .qm is included.
#

function reload() {
	export MYSTARTUPINCLUDED=; . $HOME/.bashrc
}


cat <<!!!!! > /dev/null ## skip over the rest of the script when sourcing this file

==begin alladdress
gusgrenfell.co.uk
invisiblefriend.org.uk
joanlingard.com
joanlingard.co.uk
linlithgowpicturehouse.co.uk
linlithgowscoutpost.org.uk
livingstoncrafts.co.uk
maciverarts.co.uk
post.thruniverse.co.uk
psoriasisscotland.org.uk
psoriasisscotlandpatientportal.org.uk
pushkinprizes.net
rosedenecottage.co.uk
sound.thruniverse.co.uk
thruniverse.com
thruniverse.co.uk
wishawpicturehouse.co.uk
wordpress.thruniverse.co.uk
www.joanlingard.co.uk
qmonkey.co.uk
pi.qmonkey.co.uk
eggs.qmonkey.co.uk
tv.qmonkey.co.uk
yopp.co.uk
ns1.yopp.co.uk
ns2.yopp.co.uk
mail.qmonkey.co.uk
hostgator.qmonkey.co.uk
==end

==begin alldomain
gusgrenfell.co.uk
invisiblefriend.org.uk
qmonkey.co.uk
joanlingard.com
joanlingard.co.uk
linlithgowpicturehouse.co.uk
linlithgowscoutpost.org.uk
livingstoncrafts.co.uk
maciverarts.co.uk
psoriasisscotland.org.uk
psoriasisscotlandpatientportal.org.uk
pushkinprizes.net
rosedenecottage.co.uk
thruniverse.com
thruniverse.co.uk
wishawpicturehouse.co.uk
yopp.co.uk
hostgator.qmonkey.co.uk
==end

==begin allservers
prd,prod	qm		hostgator.qmonkey.co.uk	
rmq1,rmq	qm		rmq1				GCLOUD=top-athlete-87816:us-east1-b
lemp		qm		lemp-pnyc			GCLOUD=top-athlete-87816:us-east1-b
gitter		qm		git   				GCLOUD=top-athlete-87816:europe-west1-d
core01		core	core01				GCLOUD=coretest-1187:europe-west1-d
vox			qm		vox.qmonkey.co.uk
twig,pi		qm		twig.qmonkey.co.uk
vag			vagrant	192.168.1.222
vcore		core	192.168.1.201
homer,nginx	qm    192.168.1.199
==end

!!!!!

# vi:syntax=sh 
