#!/bin/bash

# aside from whats in the notes, add arjun func(CHK), waybackurls(CHK),amass + sublist3r(CHK),whatweb(CHK),amass + subjack(CHK),
# make individual modules
#write function that pulls all UNIQUE params and organizes them(return_url > Open_redirect_maybe.txt search > xss_maybe.txt) sed might work(use regex to pull things between ? and = or>
#write in arg to chose where to output to for main fullsweep() and similar scans
# write up algo/function to generate or encode XSS chars from input payload or from scratch

halp_meh (){
        echo "[*] Usage: ./lazyrecon.sh [options] <domain>"
        echo "[*] Example: ./lazyrecon.sh -f google.com"
        echo "[*] Scan types"
        echo "          [>] -f > runs full recon suite against host(actively)"
        echo "          [>] -g > runs gitrob and opens web GUI"
        echo "          [>] -k > knockpy"
        echo "          [>] -m > compiles subdomains and runs meg with recursive assetfinder + sublist3r"
        echo "          [>] -d > runs dirsearch against host. uses 150 threads and extensions:jsp,json,asp,aspx,php,html"
        echo "          [>] -t > scans domain for subdomain takeover"
        echo "                  [*] Usage: ./lazyrecon -t <input file> <output> <target>"
        echo "          [>] -w > runs whatweb against domain"
        echo "          [>] -a > runs arjun against target for param discovery(takes a list)"
        echo "          [>] -r > certspotter one-liner"
        echo "                  [*] Usage: ./lazyrecon -r <subdomain> <output file>"
        echo "          [>] -c > Passively searches and compiles a list of subdomains and root domains from certsh, certspotter, and digicert (crtndstry)"
        echo "          [>] -e > extracts all file with specified extension."
        echo "                  [*] Usage: ./lazyrecon -e <file to pull from> <extension> <output file>. IN THAT ORDER"
        echo "Optional args:"
        echo "          [>] -l > specifies a out-of-scope list[TBA]"
        echo "          [>] -o > specifes path to save output to. If not specfied, output will be saved to dir named after target[TBA]"
        exit 1
}

xss (){
    echo "[-] Work in progress"
}

certspotter (){
    if [[ ! $1 ]] || [[ ! $2 ]];then
        url=$1
        output=$2
    fi

    curl -s https://certspotter.com/api/v0/certs\?domain\=$url | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u >> $output
}


knock (){
   url=$1
   knockpy -j $url
}

jsparser (){
    cd JSParser/
    python handler.py

    firefox 127.0.0.1:8080
}

git_search () {
    firefox 127.0.0.1:9393

    gitrob $1
}

meg_pull () {

url=$1

    if [[ ! -d "$url" ]];then
        mkdir $url
    fi

    if [[ ! -d "$url/recon" ]];then
        mkdir $url/recon
    fi

    if [[ ! -d "$url/recon/meg" ]];then
        mkdir $url/recon/meg
    fi

    cd $url/recon/meg

    assetfinder $url | grep '.url' | httprobe | sort -u | tee hosts

    for asset in $(cat hosts); do
        echo "[+] Recursively sublisting $asset..."
        sublist3r -d $asset -o output_$asset.txt
        if [[ -f "output_$asset.txt" ]];then
            cat output_$asset.txt | sort -u | tee -a hosts
            rm output_$asset.txt
        fi
    done

    meg -d 2000 -v /

    meg -d 2000 -v / | grep '(200 OK)' | tee 200s.txt

    meg -d 2000 -v / | grep '(30' | tee redirects.txt

    meg -d 2000 -v / | grep '(400' | tee 400s.txt

    meg -d 2000 -v / | grep '(50' | tee server_errors.txt
}

directorysearch (){
    cd bug_bounty_tools/recon/dirsearch
    python3 dirsearch -u $1 -t 150 -e jsp,asp,aspx,php,html,json -r
}

whatweb_scan (){
# for single domain, make one for lists later
    url=$1

    if [[ ! -d "$url" ]];then
        mkdir $url
    fi

    if [[ ! -d "$url/recon" ]];then
        mkdir $url/recon
    fi

    if [[ ! -d "$url/recon/whatweb" ]];then
        mkdir $url/recon/whatweb
    fi

    echo "[*] Pulling plugins data on $domain $(date +'%Y-%m-%d %T') "
    whatweb --info-plugins -t 50 -v $url >> $url/recon/whatweb/plugins.txt; sleep 3
    echo "[*] Running whatweb on $domain $(date +'%Y-%m-%d %T')"
    whatweb -t 50 -v $url >> $url/recon/whatweb/output.txt; sleep 3

}

crtndstry (){
# main functions courtesy of nahamsec w/ help of nukedx and dmfroberson
        url=$1
        testing_date=$(date +'%d-%m-%y')
        if [[ ! -d "$url" ]];then
                mkdir $url
        fi
        if [[ ! -d "$url/recon" ]];then
                mkdir $url/recon
        fi
        if [[ ! -d "$url/recon/crtndstry" ]];then
                mkdir $url/recon/crtndstry
        fi

        mkdir $url/recon/crtndstry/$testing_date
        mkdir $url/recon/crtndstry/$testing_date/rawdata
        mkdir $url/recon/crtndstry/$testing_date/data
        mkdir $url/recon/crtndstry/$testing_date/httprobe
        mkdir $url/recon/crtndstry/$testing_date/wayback
        mkdir $url/recon/crtndstry/$testing_date/wayback/extensions
        mkdir $url/recon/crtndstry/$testing_date/wayback/params
        mkdir $url/recon/crtndstry/$testing_date/subjack

        #give it patterns to look for within crt.sh for example %api%.site.com
        declare -a arr=("api" "corp" "dev" "uat" "test" "stag" "sandbox" "prod" "internal" "back" "old")
        for i in "${arr[@]}";do
                echo "[*] Testing $url for $i"
                #get a list of domains based on our patterns in the array
                crtsh=$(curl -s https://crt.sh/\?q\=%25$i%25.$url\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/rawdata/crtsh.txt)
        done
        curl -s https://crt.sh/\?q\=$url\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/rawdata/crtsh.txt)
        for link in $(cat $url/recon/crtndstry/$testing_date/rawdata/crtsh.txt); do curl -s https://crt.sh/\?q\=$link\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/rawdata/crtsh.txt;done
        echo "[*] Getting list of domains for $url from certspotter"
        #get a list of domains from certspotter
        certspotter=$(curl -s https://certspotter.com/api/v0/certs\?domain\=$url | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep -w $url\$ | tee $url/recon/crtndstry/$testing_date/rawdata/certspotter.txt
        #get a list of domains from digicert
        echo "[*] Getting list of domains for $url from digicert"
        digicert=$(curl -s https://ssltools.digicert.com/chainTester/webservice/ctsearch/search?keyword=$url -o ~/$url/recon/crtndstry/$testing_date/rawdata/digicert.json )
        echo "$crtsh"
        echo "$certspotter"
        echo "$digicert"

        #this creates a list of all unique root sub domains
        clear
        echo "working on data"
        cat ~/$url/recon/crtndstry/$testing_date/rawdata/crtsh.txt | rev | cut -d "."  -f 1,2,3 | sort -u | rev | tee ~/$url/recon/crtndstry/$testing_date/$url-temp.txt
        cat ~/$url/recon/crtndstry/$testing_date/rawdata/certspotter.txt | rev | cut -d "."  -f 1,2,3 | sort -u | rev | tee -a ~/$url/crtndstry/$testing_date/$url-temp.txt
        domain=$url
        jq -r '.data.certificateDetail[].commonName,.data.certificateDetail[].subjectAlternativeNames[]' ~/$url/recon/crtndstry/$testing_date/rawdata/digicert.json | sed 's/"//g' | grep -w '$domain$' | grep -v '^*.' | rev | cut -d '.'  -f 1,2,3 | sort -u | rev >> ./$1-temp.txt 
        cat ~/$url/recon/crtndstry/$testing_date/$url-temp.txt | sort -u | tee ~/$url/recon/crtndstry/$testing_date/data/$url-$(date '+%Y.%m.%d-%H.%M').txt; rm ~/$url/recon/crtndstry/$testing_date/$url-temp.txt
        echo "[*] Number of domains found: $(cat ~/$url/recon/crtndstry/$testing_date/data/$1-$(date '+%Y.%m.%d-%H.%M').txt | wc -l)"

        # run httprobe against found domains
        echo "[+] Running httprobe against compiled domains..."
        cat ~/$url/recon/crtndstry/$testing_date/rawdata/crtsh.txt | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> ~/$url/recon/crtndstry/$testing_date/httprobe/alive.txt
        cat ~/$url/recon/crtndstry/$testing_date/rawdata/certspotter.txt | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> ~/$url/recon/crtndstry/$testing_date/httprobe/alive.txt
        # add wayback and pull .html, .js, .json, .php, robots.txt, .aspx
        echo "[+] Pulling wayback data..."
        cat ~/$url/recon/crtndstry/$testing_date/httprobe/crtsh_alive.txt | waybackurls >> ~/$url/recon/crtndstry/$testing_date/wayback/crtsh_wayback_output.txt
        cat ~/$url/recon/crtndstry/$testing_date/httprobe/certspotter_alive.txt | waybackurls >> ~/$url/recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt
        # pulls robots.txt from wayback output
        echo "  [*] Compiling robots.txt from wayback data..."
        cat ~/$url/recon/crtndstry/$testing_date/wayback/crtsh_wayback_output.txt | grep 'robots.txt' >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/robots.txt
        cat ~/$url/recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt | grep 'robots.txt' >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/robots.txt
        # pulls potential params from wayback output
        echo "  [*] Pulling potential params from wayback data..."
        cat ~/$url/recon/crtndstry/$testing_date/wayback/crtsh_wayback_output.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> ~/$url/recon/crtndstry/$testing_date/wayback/params/wayback_params.txt
#       for line in $(cat ); echo $line"=";done
        cat ~/$url/recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> ~/$url/recon/crtndstry/$testing_date/wayback/params/wayback_params.txt
        echo "[+] Checking for intersting extensions from wayback data..."
        for link in $(cat ~/$url/recon/crtndstry/$testing_date/wayback/crtsh_wayback_output.txt);do
              ext="${link##*.}"
                if [[ "$ext" == "do" ]];then
                        echo "  [+] do files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/dos.txt
                fi
                if [[ "$ext" == "jsp" ]];then
                        echo "  [+] jsp files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/jsp.txt
                fi
                if [[ "$ext" == "js" ]];then
                        echo "  [+] js files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/js.txt
                fi
                if [[ "$ext" == "json" ]];then
                        echo "  [+] json files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/json.txt
                fi
                if [[ "$ext" == "php" ]];then
                        echo "  [+] php files found!"
                        echo $link | sort -u | tee -a ~/url/recon/crtndstry/$testing_date/wayback/extensions/php.txt
                fi
                if [[ "$ext" == "html" ]];then
                        echo "  [+] html files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/html.txt;
                fi
                if [[ "$ext" == "md" ]];then
                        echo "  [+] md files found!"
                        echo $link | sort -u |tee -a  ~/$url/recon/crtndstry/$testing_date/wayback/extensions/md.txt
                fi
                if [[ "$ext" == "xml" ]];then
                        echo "  [+] xml files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/xml.txt
                fi
                if [[ "$ext" == "cgi" ]];then
                        echo "  [+] cgi files found!"
                        echo $link | sort -u |tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/cgi.txt
                fi
        done
        echo "[+] Checking for interesting extensions from wayback data..."

        for link in $(cat ~/$url/recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt);do
                ext="${link##*.}"
                if [[ "$ext" == "do" ]]; then
                        echo "  [+] do files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/dos.txt
                fi
                if [[ "$ext" == "jsp" ]];then
                        echo "  [+] jsp files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/jsp.txt
                fi
                if [[ "$ext" == "js" ]];then
                        echo "  [+] js files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/js.txt
                fi
                if [[ "$ext" == "json" ]];then
                        echo "  [+] json files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/json.txt
                fi
                if [[ "$ext" == "php" ]];then
                        echo "  [+] php files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/php.txt
                fi
                if [[ "$ext" == "html" ]];then
                        echo "  [+] html files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/html.txt
                fi
                if [[ "$ext" == "md" ]]; then
                        echo "  [+] md files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/md.txt
                fi
                if [[ "$ext" == "xml" ]]; then
                        echo "  [+] xml files found!"
                        echo $link | sort -u | tee -a  ~/$url/recon/crtndstry/$testing_date/wayback/extensions/xml.txt
                fi
                if [[ "$ext" == "cgi" ]]; then
                        echo "  [+] cgi files found!"
                        echo $link | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/wayback/extensions/cgi.txt
                fi
        done

        # add subjack cmd that runs agasint all subdomains found
        echo "[*] Scanning for potential subdomain takeover..."
        subjack -w ~/$url/recon/crtndstry/$testing_date/rawdata/crtsh.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 >> ~/$url/recon/crtndstry/$testing_date/potential_takeover/potential_takeovers.txt
        subjack -w ~/$url/recon/crtndstry/$testing_date/rawdata/certspotter.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 >> ~/$url/recon/crtndstry/$testing_date/potenial_takeover/potential_takeovers.txt
}

full_sweep (){

    url=$1
    if [ ! -d "$url" ];then
        mkdir $url
    fi
    if [ ! -d "$url/recon" ];then
        mkdir $url/recon
    fi
    if [ ! -d "$url/recon/3rd-lvls" ];then
        mkdir $url/recon/3rd-lvls
    fi
    if [ ! -d "$url/recon/scans" ];then
        mkdir $url/recon/scans
    fi
    if [ ! -d "$url/recon/httprobe" ];then
        mkdir $url/recon/httprobe
    fi
    if [ ! -d "$url/recon/potential_takeovers" ];then
        mkdir $url/recon/potential_takeovers
    fi
    if [ ! -d "$url/recon/wayback" ];then
        mkdir $url/recon/wayback
    fi
    if [ ! -d "$url/recon/wayback/params" ];then
        mkdir $url/recon/wayback/params
    fi
    if [ ! -d "$url/recon/wayback/extensions" ];then
        mkdir $url/recon/wayback/extensions
    fi

    if [ ! -d "$url/recon/whatweb" ];then
        mkdir $url/recon/whatweb
    fi
    if [ ! -f "$url/recon/httprobe/alive.txt" ];then
        touch $url/recon/httprobe/alive.txt
    fi
    if [ ! -f "$url/recon/final.txt" ];then
        touch $url/recon/final.txt
    fi
    if [ ! -f "$url/recon/3rd-lvl" ];then
        touch $url/recon/3rd-lvl-domains.txt
    fi

    echo "[+] Harvesting subdomains with assetfinder..."
    assetfinder $url | grep '.$url' | sort -u | tee -a $url/recon/final1.txt

    echo "[+] Double checking for subdomains with amass and certspotter..."
    amass enum -d $url | tee -a $url/recon/final1.txt
    #curl -s https://certspotter.com/api/v0/certs\?domain\=$url | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u
    certspotter | tee -a $url/recon/final1.txt
    sort -u $url/recon/final1.txt >> $url/recon/final.txt
    rm $url/recon/final1.txt

    echo "[+] Compiling 3rd lvl domains..."
#    cat ~/$url/recon/domains_first_pass.txt | grep -Po '(\w+\.\w+\.\w+)$' | sort -u >> ~/$url/recon/3rd-lvl-domains.txt
    cat ~/$url/recon/final.txt | grep -Po '(\w+\.\w+\.\w+)$' | sort -u >> ~/$url/recon/3rd-lvl-domains.txt
    #write in line to recursively run thru final.txt
    for line in $(cat $url/recon/3rd-lvl-domains.txt);do echo $line | sort -u | tee -a $url/recon/final.txt;done

    echo "[+] Harvesting full 3rd lvl domains with sublist3r..."
    for domain in $(cat $url/recon/3rd-lvl-domains.txt);do sublist3r -d $domain -o $url/recon/3rd-lvls/$domain.txt;done

    echo "[+] Probing for alive domains..."
    cat $url/recon/final.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> $url/recon/httprobe/alive.txt
    sort -u $url/recon/httprobe/alive.txt

    echo "[+] Checking for possible subdomain takeover..."
    if [ ! -f "$url/recon/potential_takeovers/domains.txt" ];then
        touch $url/recon/potential_takeovers/domains.txt
    fi
    if [ ! -f "$url/recon/potential_takeovers/potential_takeovers1.txt" ];then
        touch $url/recon/potential_takeovers/potential_takeovers1.txt
    fi
    for line in $(cat ~/$url/recon/final.txt);do echo $line |sort -u >> ~/$url/recon/potential_takeovers/domains.txt;done
    subjack -w $url/recon/httprobe/alive.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 >> $url/recon/potential_takeovers/potential_takeovers/potential_takeovers1.txt
    sort -u $url/recon/potential_takeovers/potential_takeovers1.txt >> $url/recon/potential_takeovers/potential_takeovers.txt
    rm $url/recon/potential_takeovers/potential_takeovers1.txt

    echo "[+] Running whatweb on compiled domains..."
    for domain in $(cat ~/$url/recon/httprobe/alive.txt);do
        if [ ! -d  "$url/recon/whatweb/$domain" ];then
            mkdir $url/recon/whatweb/$domain
        fi
        if [ ! -d "$url/recon/whatweb/$domain/output.txt" ];then
            touch $url/recon/whatweb/$domain/output.txt
        fi
        if [ ! -d "$url/recon/whaweb/$domain/plugins.txt" ];then
            touch $url/recon/whatweb/$domain/plugins.txt
        fi

        echo "[*] Pulling plugins data on $domain $(date +'%Y-%m-%d %T') "
        whatweb --info-plugins -t 50 -v $domain >> $url/recon/whatweb/$domain/plugins.txt; sleep 3
        echo "[*] Running whatweb on $domain $(date +'%Y-%m-%d %T')"
        whatweb -t 50 -v $domain >> $url/recon/whatweb/$domain/output.txt; sleep 3
    done

    echo "[+] Scraping wayback data..."
    cat $url/recon/final.txt | waybackurls | tee -a  $url/recon/wayback/wayback_output1.txt
    sort -u $url/recon/wayback/wayback_output1.txt >> $url/recon/wayback/wayback_output.txt
    rm $url/recon/wayback/wayback_output1.txt

    echo "[+] Pulling and compiling all possible params found in wayback data..."
    cat $url/recon/wayback/wayback_output.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> $url/recon/wayback/params/wayback_params.txt
    for line in $(cat $url/recon/wayback/params/wayback_params.txt);do echo $line'=';done

    echo "[+] Pulling and compiling js/php/aspx/jsp/json files from wayback output..."
    for line in $(cat $url/recon/wayback/wayback_output.txt);do
        ext="${line##*.}"
        if [[ "$ext" == "js" ]]; then
            echo $line >> $url/recon/wayback/extensions/js.txt
            sort -u $url/recon/extensions/js.txt
        fi
        if [[ "$ext" == "html" ]];then
            echo $line >> $url/recon/wayback/extensions/jsp.txt
            sort -u $url/recon/wayback/extensions/jsp.txt
        fi
        if [[ "$ext" == "json" ]];then
            echo $line >> $url/recon/wayback/extensions/json.txt
            sort -u $url/recon/wayback/extensions/json.txt
        fi
        if [[ "$ext" == "php" ]];then
            echo $line >> $url/recon/wayback/extensions/php.txt
            sort -u $url/recon/wayback/extensions/php.txt
        fi
        if [[ "$ext" == "aspx" ]];then
            echo $line >> $url/recon/wayback/extensions/aspx.txt
            sort -u $url/recon/wayback/extensions/aspx.txt
        fi
    done

    echo "[+] Scanning for open ports..."
    nmap -iL $url/recon/httprobe/alive.txt -T4 -oA $url/recon/scans/scanned.txt

    echo "[+] Running eyewitness against all compiled domains..."
    python3 EyeWitness/EyeWitness.py --web -f $url/recon/httprobe/alive.txt -d $url/recon/eyewitness --resolve
}

param_discovery (){
    target_lst=$1
    cd ~/Arjun
    for target in $(cat $target_lst);do
        python3 arjun.py -u $target -t 50 >> $url/recon/arjun/$target.txt
    done
}

extension_extractor (){
    if [[ ! $1 ]] || [[ ! $2 ]] || [[ ! $3 ]];then
      echo '[-] Invalid positional arguements'
    fi

    file=$1
    ext_pulled=$2
    outpath=$3

    for line in $(cat $file);do
        ext="${line##*.}"
        if [[ "$ext" == "$ext_pulled" ]];then echo $line >> $outpath; fi
    done
}

sub_check (){
    if [[ ! $1 ]] || [[ ! $2 ]] || [[ ! $3 ]];then
        echo "[-] Invalid positional arguments"
    fi

    file=$1
    output=$2
    target=$3

    assetfinder $target | grep '.$target' | sort -u | tee -a assetfinder_$output.txt
    subjack -w assetfinder_$output.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 >> $output
}

# write options for all in halp_meh and to-do
while getopts "f:a:e:d:c:hjg:m:w:" opt; do
      case ${opt} in
           f )
             full_sweep $OPTARG
             exit 1
             ;;
           h )
             halp_meh
             exit 1
             ;;
           a )
             param_discovery $OPTARG

             exit 1
             ;;
           e )
             extension_extractor $OPTARG
             exit 1
             ;;
           d )
             directorysearch $OPTARG
             exit 1
             ;;
           c )
             crtndstry $OPTARG
             exit 1
             ;;
           j )
             jsparser
             ;;
           t )
             sub_check $OPTARG
             exit 1
             ;;
           g )
             git_search $OPTARG
             ;;
           m )
             meg_pull $OPTARG
             exit 1
             ;;
           w )
             whatweb_scan $OPTARG
             exit 1
             ;;
           k )
             knock $OPTARG
             exit 1
             ;;
      esac
done
shift $((OPTIND -1))
