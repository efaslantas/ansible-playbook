#!/bin/bash

##ONKOSUL
#docker registry'nin -e REGISTRY_STORAGE_DELETE_ENABLED=true  opsiyonu ile calisiyor olması gerekir
#docker run -d -p 5000:5000 --restart=always --name registry   -v /opt/docker-registry/data:/var/lib/registry   -v /opt/docker-registry/auth:/auth   -e "REGISTRY_AUTH=htpasswd"   -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm"   -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd   -v /opt/docker-registry/cert:/certs   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry_auth.crt   -e REGISTRY_HTTP_TLS_KEY=/certs/registry_auth.key   -e REGISTRY_STORAGE_DELETE_ENABLED=true   registry:2.7.0


if [[ $1 == "-h" ]]
then
echo "usage: $0 <option> <suboption>"
echo "options: list/delete
list ile imajları listeleriz.
<suboptions for list>
--all  ile bütün imajları listeleriz.
--app=manager (or appname)  ile sadece o tag'deki uygulamalarımızın imajlarını listeleriz.
delete ile imajlarımızı sileriz.
<suboptions for delete>
--all  ile bütün imajlarımızı sileriz.
--app=manager ( or app-name )  sadece ilgili tag'deki uygulamamızın imajlarını sileriz.
--keep=10 (or n )   son 10 tanesini yada n tanesini bırakırız.
"
exit 1;
fi

REGISTRY_BASE_PATH=/opt/docker-registry/data/docker/registry/v2/repositories

#Connection info
username="admin"
password='PasswTD123!'
uiport=96
uiaddress="127.0.0.1"

## suboption var ise ilgili kismi almak icin
if [[ $2 =~ "--app=" ]]
then
        appname=${2:6}
fi

if [[ $3 =~ "--keep=" ]]
then
        keepme=${3:7}
        if [[ $keepme -lt 3 ]]
        then
                keepme=4
        fi
fi

get_tags () {

if [[ $1 != "appname" ]]
then
  for i in $(ls $REGISTRY_BASE_PATH)
  do
        echo "----------------------------------"
    echo "tag name is: $i"
    num_tags=$(ls -ltr $REGISTRY_BASE_PATH/$i/_manifests/tags/ | awk '{print $9}' | wc -l)
    num_tags=$(($num_tags - 1 ))   #birtane bos satir geliyor
    tags=$(ls -ltr $REGISTRY_BASE_PATH/$i/_manifests/tags/ | awk '{print $9}' )
    echo "number of versions: $num_tags"
    echo "tags are: $tags"
  done
elif [[ $1 == "appname" ]]
then
        echo "----------------------------------"
        ls $REGISTRY_BASE_PATH/$appname 1>/dev/null 2>&1
        if [[ $? != 0 ]]
        then
                echo "no app/tag found. check your image name with  list --all "
                exit 1;
        fi
        echo "tag name is: $appname"
        num_tags=$(ls -ltr $REGISTRY_BASE_PATH/$appname/_manifests/tags/ | awk '{print $9}' | wc -l)
        num_tags=$(($num_tags - 1))
        tags=$(ls -ltr $REGISTRY_BASE_PATH/$appname/_manifests/tags/ | awk '{print $9}' )
        echo "number of versions: $num_tags"
        echo "tags are: $tags"
fi
}


delete_tags () {
echo "delete tags icinde $1 geldi"
if [[ $1 != "appname" ]]
then
  for i in $(ls $REGISTRY_BASE_PATH)
  do
    echo "----------------------------------"
    echo "tag name is: $i"
    num_tags=$(ls -ltr $REGISTRY_BASE_PATH/$i/_manifests/tags/ | awk '{print $9}' | wc -l)
    num_tags=$(($num_tags - 1))
    echo "number of versions: $num_tags"
    if [[ $(($num_tags - $keepme)) -gt 1 ]]
    then
        silinecekler=$(ls -ltr $REGISTRY_BASE_PATH/$i/_manifests/tags/ | awk '{print $9}' | head -n $(($num_tags - $keepme)))
        echo "silinecek imajların versiyonları"
        echo "$silinecekler"
        kalacaklar=$(ls -ltr $REGISTRY_BASE_PATH/$i/_manifests/tags/ | awk '{print $9}' | tail -n -$keepme)
                for n in $(echo $silinecekler)
                do
                        mydigesttag=$(ls $REGISTRY_BASE_PATH/$i/_manifests/tags/$n/index/sha256/)
                        echo "$n:$mydigesttag"
                        mydigestrev=$(basename $REGISTRY_BASE_PATH/$i/_manifests/revisions/sha256/$mydigesttag)
                        echo "$n:$mydigestrev"
                        curl -v -X DELETE -u "$username:$password" http://$uiaddress:$uiport/v2/$i/manifests/sha256:$mydigesttag
                done
        echo "geriye kalacakların versiyonları"
        echo "$kalacaklar"

     else
        echo "$keepme adet kalsin istediginiz icin $i icin silinecek imaj bulunmuyor"
     fi
 done
elif [[ $1 == "appname" ]]
then
                echo "----------------------------------"
                echo "tag name is: $appname"
                num_tags=$(ls -ltr $REGISTRY_BASE_PATH/$appname/_manifests/tags/ | awk '{print $9}' | wc -l)
                num_tags=$(($num_tags - 1))
                echo "number of versions: $num_tags"
                if [[ $(($num_tags - $keepme)) -gt 1 ]]
                then
                silinecekler=$(ls -ltr $REGISTRY_BASE_PATH/$appname/_manifests/tags/ | awk '{print $9}' | head -n $(($num_tags - $keepme)))
                echo "silinecek imajların versiyonları"
                echo "$silinecekler"
                kalacaklar=$(ls -ltr $REGISTRY_BASE_PATH/$appname/_manifests/tags/ | awk '{print $9}' | tail -n -$keepme)
                        for n in $(echo $silinecekler)
                        do
                                mydigesttag=$(ls $REGISTRY_BASE_PATH/$appname/_manifests/tags/$n/index/sha256/)
                                echo "$n:$mydigesttag"
                                mydigestrev=$(basename $REGISTRY_BASE_PATH/$appname/_manifests/revisions/sha256/$mydigesttag)
                                echo "$n:$mydigestrev"
                                curl -v -X DELETE -u "$username:$password" http://$uiaddress:$uiport/v2/$appname/manifests/sha256:$mydigesttag
                        done
                echo "geriye kalacakların versiyonları"
                echo "$kalacaklar"

                else
                        echo "$keepme adet kalsin istediginiz icin $appname icin silinecek imaj bulunmuyor"
                fi
fi
}


## PROGRAM START
## Eger Option  list ise yapilacaklar.

if [[ $1 == "list" && $2 == "--all" ]]
then
        get_tags

elif [[ $1 == "list" &&  $2 =~ "--app=" ]]
then
         get_tags appname
fi


## Eger option  delete ise yapilacaklar. Not güvenlik icin default en az son 4 imaj kalsın ayarlandı

if [[ $1 == "delete" && $2 == "--all" ]]
then
        if [[ $3 != '' && $keepme -gt 3 ]]
        then
                delete_tags
                docker exec -it -u root registry bin/registry garbage-collect /etc/docker/registry/config.yml
        elif [[ $3 == '' ]]
        then
                keepme=4
                delete_tags
                docker exec -it -u root registry bin/registry garbage-collect /etc/docker/registry/config.yml
        fi
fi



if [[ $1 == "delete" && $appname != '' ]]
then
        if [[ $3 != '' && $keepme -gt 3 ]]
        then
                delete_tags appname
                docker exec -it -u root registry bin/registry garbage-collect /etc/docker/registry/config.yml
        elif [[ $3 == '' ]]
        then
                keepme=4
                delete_tags appname
                docker exec -it -u root registry bin/registry garbage-collect /etc/docker/registry/config.yml
        fi
fi
