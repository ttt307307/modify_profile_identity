#!/bin/bash
#get the CODE_SIGN_IDENTITY from file ?.mobileprovision and modify CODE_SIGN_IDENTITY in project.pbxproj

#create a temp.plist form mobileprovision with security; security cms -D -i path_to_mobileprovision > temp.plist
#read the DeveloperCertificates from temp.plist with PlistBuddy; /usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' temp.plist > cert.txt
#get the CODE_SIGN_IDENTITY value form cert.txt with openssl; cat cert.txt | base64 -D | openssl x509 -subject -inform der | head -n 1

#modify the file project.pbxproj
#从project.pbxproj中读出/* Debug */ = {，/* Release */ = { 所在行的内容和行号，并对行号排序（需要区分是Debug/Release），并获取对应的UUID,
#用plutil命令将project.pbxproj转化成plist格式，根据UUID读出对应的CODE_SIGN_IDENTITY值，并在project.pbxproj修改，为了防止每个值只有一次有效的修改，替换的时候每次替换从对应的行号到文本结束


cd "$(dirname "$0")"

PATH_PBXPROJ=/Users/tandewei/work_space/arpg/client/_ide_xcode/itoolsfbzs/itoolsfbzs.xcodeproj/project.pbxproj
FILE_DEV_PROVISION=/Users/tandewei/Documents/key/arpg证书/arpg_first_wave/ios_identifiers/moshenitools/arpg0000moshen0000itools_dev.mobileprovision
FILE_INHOUSE_PROVISION=/Users/tandewei/Documents/key/arpg证书/arpg_first_wave/ios_identifiers/moshenitools/arpg0000moshen0000itools_inhouse.mobileprovision


IDENTITY_DEBUG=""
IDENTITY_RELEASE=""

TEMP_PLIST_FILE="temp.plist"
PROJECT_PLIST="project.plist"

#标识修改次数
MODIFYED_TIMES=0

#用法简介
function usage()
{
    echo 'usage:'
    echo 'sh identityhelper.sh [pbxproj_file] [debug_provision_file] [release_provision_file]'
}

#根据mobileprovision文件获取CODE_SIGN_IDENTITY
function get_identity()
{
    if [ -f "${TEMP_PLIST_FILE}" ];then
	rm ${TEMP_PLIST_FILE}
    fi
    echo "create ${TEMP_PLIST_FILE} from ${FILE_DEV_PROVISION}"
    security cms -D -i ${FILE_DEV_PROVISION} > ${TEMP_PLIST_FILE}
    identity_str=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' ${TEMP_PLIST_FILE} | openssl x509 -subject -inform der | head -n 1`
    echo "identity_str=${identity_str}"
    IDENTITY_DEBUG=`echo "${identity_str}" | cut -d "/" -f3 | cut -d "=" -f2`
    echo "IDENTITY_DEBUG:${IDENTITY_DEBUG}"

    if [ -f "${TEMP_PLIST_FILE}" ];then
	rm ${TEMP_PLIST_FILE}
    fi
    echo "create ${TEMP_PLIST_FILE} from ${FILE_INHOUSE_PROVISION}"
    security cms -D -i ${FILE_INHOUSE_PROVISION} > ${TEMP_PLIST_FILE}
    identity_str=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' ${TEMP_PLIST_FILE} | openssl x509 -subject -inform der | head -n 1`
    echo "identity_str=${identity_str}"
    IDENTITY_RELEASE=`echo "${identity_str}" | cut -d "/" -f3 | cut -d "=" -f2`
    echo "IDENTITY_RELEASE:${IDENTITY_RELEASE}"
}


#修改project.pbxproj
function modify_pbxproj()
{
    echo "modify_pbxproj..."
    cp -f ${PATH_PBXPROJ} ${PATH_PBXPROJ}.backup
    
    if [ -f "${PROJECT_PLIST}" ];then
	rm ${PROJECT_PLIST}
    fi

    echo "create ${PROJECT_PLIST} from ${PATH_PBXPROJ}"
    plutil -convert xml1 ${PATH_PBXPROJ} -o ${PROJECT_PLIST}

    #read UUID by /* Debug */ = { and /* Release */ = {
    echo 'read UUID by "/* Debug */ = {" and "/* Release */ = {" from project.pbxproj'
    uuid_dr_str=`cat ${PATH_PBXPROJ} | grep -n -E "\\\/\\\* [Debug,Release]* \\\*\\\/ = {"`
    echo "uuid_dr_dtr:\n${uuid_dr_str}"

    declare -a array_uuid_lines
    declare -a array_uuid_values

    test=`echo "${uuid_dr_str//[\*, ,\n,\/,=]}"`

    test=`echo "${test//Debug}"`
    test=`echo "${test//Release}"`
    echo "test=\n${test}"

    i=1
    while((1==1))
    do
	split=`echo ${test} | cut -d "{" -f${i}`
	if [ "${split}" != "" ];then
#	    echo "${i}:${split// }"
	    array_uuid_lines[$[i]]=`echo ${split// } | cut -d ":" -f1`
	    echo "array_uuid_lines[${i}]=${array_uuid_lines[$[i]]}"
	    array_uuid_values[${i}]=`echo ${split// } | cut -d ":" -f2`
	    echo "array_uuid_values[${i}]=${array_uuid_values[${i}]}"
	    ((i++))
	else
	    break
	fi
    done


    #遍历array_uuid_values的值uuid，下标记为index，根据uuid在PROJECT_PLIST文件中读取对应的name的值,以便判断是Debug或Release，从行号array_uuid_lines[index]开始，在文件PATH_PBXPROJ中全局替换，这样做是为了保证Debug或Release对应的CODE_SIGN_IDENTITY值被有效的修改一次
    tag_index=0
    uuid_line=${array_uuid_lines[1]}
    for uuid_value in ${array_uuid_values[@]}
    do
	((tag_index++))
	uuid_line=${array_uuid_lines[${tag_index}]}
	echo "uuid_line=${uuid_line}"
	echo "uuid_value=${uuid_value}"

	temp_identity_name=`/usr/libexec/PlistBuddy -c "Print objects:${uuid_value}:name" ${PROJECT_PLIST}`
	echo "temp_identity_name=${temp_identity_name}"

	if [ ${temp_identity_name} == "Debug" ];then
#	    temp_identity_value=`/usr/libexec/PlistBuddy -c "Print objects:${uuid_value}:buildSettings:CODE_SIGN_IDENTITY" ${PROJECT_PLIST}`
	    echo 'replease CODE_SIGN_IDENTITY = "*" with '${IDENTITY_DEBUG}
	    sed -i "" -E "${array_uuid_lines[$[tag_index]]},\$s/CODE_SIGN_IDENTITY = \"[^\"]*\"/CODE_SIGN_IDENTITY = \"${IDENTITY_DEBUG}\"/g" ${PATH_PBXPROJ}

	    if [ $? -eq 0 ];then
		((MODIFYED_TIMES++))
	    fi
	    
	    echo 'replease "CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "*" with '${IDENTITY_DEBUG}
	    sed -i "" -E "${array_uuid_lines[$[tag_index]]},\$s/\"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\" = \"[^\"]*\"/\"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\" = \"${IDENTITY_DEBUG}\"/g" ${PATH_PBXPROJ}
	    if [ $? -eq 0 ];then
		((MODIFYED_TIMES++))
	    fi
	    
	elif [ ${temp_identity_name} == "Release" ];then
	    echo 'replease CODE_SIGN_IDENTITY = "*" with '${IDENTITY_RELEASE}
	    sed -i "" -E "${array_uuid_lines[$[tag_index]]},\$s/CODE_SIGN_IDENTITY = \"[^\"]*\"/CODE_SIGN_IDENTITY = \"${IDENTITY_RELEASE}\"/g" ${PATH_PBXPROJ}

	    if [ $? -eq 0 ];then
		((MODIFYED_TIMES++))
	    fi

	    echo 'replease "CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "*" with '${IDENTITY_RELEASE}
	    sed -i "" -E "${array_uuid_lines[$[tag_index]]},\$s/\"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\" = \"[^\"]*\"/\"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\" = \"${IDENTITY_RELEASE}\"/g" ${PATH_PBXPROJ}
	    if [ $? -eq 0 ];then
		((MODIFYED_TIMES++))
	    fi
	else
	    echo 'no match name "Debug" or "Release"'
	fi
    done
    
#    lines=` echo "${uuid_dr_str//[\*,\s,\n,\/,Debug,Release,=]}" | cut -d "{" -f1 | cut -d ":" -f1`
#    echo "${lines}"
#    uuids=` echo "${uuid_dr_str//[\*,\s,\n,\/,Debug,Release,=]}" | cut -d "{" -f1 | cut -d ":" -f2`
#    echo "${uuids}"

    
    
#    uuid_release_str=`cat ${PATH_PBXPROJ} | grep -n "\\\/\\\* Release \\\*\\\/ = {"`
#    echo "uuid_release_str:\n${uuid_release_str}"

    
#    test="${uuid_release_str//[\*, , \/,]}"
#    echo ${test}
    
    
    
    if [ ${MODIFYED_TIMES} -gt 0 ];then
	echo "modify times is:${MODIFYED_TIMES}"
	echo "cat ${PATH_PBXPROJ}.backup | grep CODE_SIGN_IDENTITY  ===>"
	cat ${PATH_PBXPROJ}.backup | grep -n CODE_SIGN_IDENTITY
	echo "                       ||                       "
	echo "                       ||                       "
	echo "                       ||                       "
	echo "                       \/                       "
	echo "cat ${PATH_PBXPROJ} | grep CODE_SIGN_IDENTITY  ===>"
	cat ${PATH_PBXPROJ} | grep -n CODE_SIGN_IDENTITY
    else
	echo "no modify!!!"
    fi
    
}


#参数解析
function parser_args()
{
    while getopts hp:d:r: opt
    do
	case "$opt" in
	    h)
		#帮助
		usage
		;;
	    p)
		#pbxproj文件全路径
		FILE_PBXPROJ=$OPTARG
		echo "FILE_PBXPROJ=${FILE_PBXPROJ}"
		;;
	    d)
		#debug_mobileprovision文件全路径
		FILE_DEV_PROVISION=$OPTARG
		echo "FILE_DEV_PROVISION=${FILE_DEV_PROVISION}"
		;;
	    r)
		#release_mobileprovision文件全路径
		FILE_INHOUSE_PROVISION=${OPTARG}
		echo "FILE_INHOUSE_PROVISION=${FILE_INHOUSE_PROVISION}"
		;;
	    \?)
		echo "no match the opt:$opt"
		usage
		exit 1
		;;
	esac	
    done

    if [ "${PATH_PROJECT}" == "" -a "${FILE_PBXPROJ}" == "" ];then
	usage "Need -P to set project path or -p to set pbxproj file."
	exit 1
    fi

    if [ "${PATH_PROVISION}" == "" ] && [ "${FILE_DEV_PROVISION}" == "" -o "${FILE_INHOUSE_PROVISION}" == "" ];then
       usage "Need -D to set mobileprovision directory or -d -r to set mobileprovision file"
       exit 1
    fi
}


function init()
{
    parser_args
}

main()
{
#    init $@
    get_identity
    if [ "${IDENTITY_DEBUG}" != "" -a "${IDENTITY_RELEASE}" != "" ];then	
	modify_pbxproj
    else
	echo 'IDENTITY_DEBUG or IDENTITY_RELEASE is error!!!'
    fi
    
}

main $@
