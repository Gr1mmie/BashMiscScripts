crtndstry (){
# main functions courtesy of nahamsec w/ help of nukedx and dmfroberson
        url=$1
        testing_date=$(date +'%D')
        if [ ! -d "$url" ];then
                mkdir $url
        fi
        if [ ! -d "$url/recon" ];then
                mkdir $url/recon
        fi

        mkdir $url/recon/crtndstry
        mkdir $url/recon/crtndstry/$testing_date
        mkdir $url/recon/crtndstry/$testing_date/rawdata
        mkdir $url/recon/crtndstry/$testing_date/data
        mkdir $url/recon/crtndstry/$testing_date/httprobe
        mkdir $url/recon/crtndstry/$testing_date/eyewitness
        mkdir $url/recon/crtndstry/$testing_date/wayback
        mkdir $url/recon/crtndstry/$testing_date/wayback
        mkdir $url/recon/crtndstry/$testing_date/wayback/extensions
        mkdir $url/recon/crtndstry/$testing_date/wayback/params
        mkdir $url/recon/crtndstry/$testing_date/subjack

         #give it patterns to look for within crt.sh for example %api%.site.com
        declare -a arr=("api" "corp" "dev" "uat" "test" "stag" "sandbox" "prod" "internal")
        for i in "${arr[@]}"
                do
                        echo "[*] Testing $url for $i"
                        #get a list of domains based on our patterns in the array
                        crtsh=$(curl -s https://crt.sh/\?q\=%25$i%25.$url\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee -a ~/$url/recon/crtndstry/$testing_date/ra>
                done
        echo "[*] Getting list of domains for $url from certspotter"
        #get a list of domains from certspotter
        certspotter=$(curl -s https://certspotter.com/api/v0/certs\?domain\=$url | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep -w $url\$ | tee $url/recon/crtndst>
        #get a list of domains from digicert
        echo "[*] Getting list of domains for $url from digicert"
        digicert=$(curl -s https://ssltools.digicert.com/chainTester/webservice/ctsearch/search?keyword=$url -o ~/$url/recon/crtndstry/$testing_data/rawdata/digicert.json)
        echo "$crtsh"
        echo "$certspotter"
        echo "$digicert"        #this creates a list of all unique root sub domains
        clear
        echo "working on data"
        cat ~/$url/recon/crtndstry/$testing_date/rawdata/crtsh.txt | rev | cut -d "."  -f 1,2,3 | sort -u | rev | tee ~/$url/recon/crtndstry/$testing_date/$url-temp.txt
        cat ~/$url/recon/crtndstry/$testing_date/rawdata/certspotter.txt | rev | cut -d "."  -f 1,2,3 | sort -u | rev | tee -a ~/$url/crtndstry/$testing_date/$url-temp.txt
        domain=$url
        jq -r '.data.certificateDetail[].commonName,.data.certificateDetail[].subjectAlternativeNames[]' ~/$url/recon/crtndstry/$testing_date/rawdata/digicert.json | sed 's/"//g' | grep -w >
        cat ~/$url/recon/crtndstry/$testing_date/$url-temp.txt | sort -u | tee ~/$url/recon/crtndstry/$testing_date/data/$url-$(date "+%Y.%m.%d-%H.%M").txt; rm ~/$url/recon/crtndstry/$testi>
        echo "Number of domains found: $(cat ~/$url/crtndstry/data/$1-$(date "+%Y.%m.%d-%H.%M").txt | wc -l)"

        # run httprobe against found domains
        cat ~/$url/recon/crtndstry/$testing_date/rawdata/crtsh.txt | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" >> ~/$url/recon/crtndstry/$testing_date/httprobe/crtsh_>
        cat ~/$url/recon/crtndstry/$testing_date/rawdata/certspotter.txt | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" >> ~/$url/recon/crtndstry/$testing_date/httprobe/>
        # add wayback and pull .html, .js, .json, .php, robots.txt, .aspx
        cat ~/$url/recon/crtndstry/$testing_date/htttprobe/crtsh_alive.txt | waybackurls >> ~/$url/recon/crtndstry/$testing_date/wayback/crtsh_wayback_output.txt
        cat ~/$url/recon/crtndstry/$testing_date/httprobe/certspotter_alive.txt | waybackurls >> ~/$url.recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt
        # pulls robots.txt from wayback output
        cat ~/$url/recon/crtndstry/$testing_date/wayback/crtsh_wayback_output.txt | grep 'robots.txt' >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/robots.txt
        cat ~/$url/recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt | grep 'robots.txt' >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/robots.txt
        # pulls potential params from wayback output
        cat ~/$url/recon/crtndstry/$testing_date/wayback/crtsh_wayback_output.txt | grep 'robots.txt' >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/robots.txt
        cat ~/$url/recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt | grep 'robots.txt' >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/robots.txt
        # pulls potential params from wayback output
        cat ~/$url/recon/crtndstry$testing_date/wayback/crtsh_wayback_output.txt | grep '?*=' " | cut -d '=' -f 1 | sort -u >> ~/$url/recon/crtndstry/$testing_date/wayback/params/potential_>
        cat ~/$url/recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> ~/$url/recon/crtndstry/$testing_date/wayback/params/poten>
        for link in $(cat ~/$url/recon/crtndstry/$testing_date/wayback/crtsh_wayback_output.txt);do
                ext="${link##*.}"
                if [[ "$ext" == "js" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/js.txt
                fi
                if [[ "$ext" == "json" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/json.txt
                fi
                if [[ "$ext" == "php" ]];then
                        echo $link >> ~/url/recon/crtndstry/$testing_date/wayback/extensions/php.txt
                fi
                if [[ "$ext" == "html" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/html.txt
                fi
        for link in $(cat ~/$url/recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt);do
               ext="${link##*.}"
                if [[ "$ext" == "js" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/js.txt
                fi
                if [[ "$ext" == "json" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/json.txt
                fi
                if [[ "$ext" == "php" ]];then
                        echo $link >> ~/url/recon/crtndstry/$testing_date/wayback/extensions/php.txt
                fi
                if [[ "$ext" == "html" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/html.txt
                fi
        for link in $(cat ~/$url/recon/crtndstry/$testing_date/wayback/certspotter_wayback_output.txt);do
                if [[ "$ext" == "js" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/js.txt
                fi
                if [[ "$ext" == "json" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/json.txt
                fi
                if [[ "$ext" == "php" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/php.txt
                fi
                if [[ "$ext" == "html" ]];then
                        echo $link >> ~/$url/recon/crtndstry/$testing_date/wayback/extensions/html.txt
                fi
        # add subjack cmd that runs agasint all subdomains found
        subjack -w ~/$url/recon/crtndstry/$testing_date/rawdata/crtsh.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 >> ~/$url/recon/crtndstry/$tes>
        subjack -w ~/$url/recon/crtndstry/$testing_date/rawdata/certspotter.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 >> ~/$url/recon/crtndstr>
        # run eyewitness against discovered subdomains
        #python3 EyeWitness/Eyewitness.py --web
}

