#!/bin/bash

#导入描述文件，读取描述文件中的uuid，作为新文件名，并复制新文件到~/Library/MobileDevice/Provisioning\ Profiles/
#修改对应工程的project.pbxproj配置

cd "$(dirname "$0")"

PATH_PBXPROJ=/Users/tandewei/work_space/arpg/client/_ide_xcode/itoolsfbzs/itoolsfbzs.xcodeproj/project.pbxproj
PATH_PROFILES=~/Library/MobileDevice/Provisioning\ Profiles/
KEY=UUID

FILE_DEV_PROVISION=/Users/tandewei/Documents/key/arpg证书/arpg_first_wave/ios_identifiers/moshenitools/arpg0000moshen0000itools_dev.mobileprovision
FILE_INHOUSE_PROVISION=/Users/tandewei/Documents/key/arpg证书/arpg_first_wave/ios_identifiers/moshenitools/arpg0000moshen0000itools_inhouse.mobileprovision
UUID_DEV_PROVISION=0
UUID_INHOUSE_PROVISION=0

#用法简介
function usage()
{
    echo 'usage:'
    echo 'sh provisionhelper.sh [pbxproj_file] [debug_provision_file] [release_provision_file]'
}


#获取描述文件的uuid
function get_uuid()
{
    echo "get_uuid..."
    local uuid_dev_str=`grep -a ${KEY} -A1 ${FILE_DEV_PROVISION}`
    local uuid_dev=`echo ${uuid_dev_str} | sed -E "s/\\<string\\>(.*)\\<\\/string\\>/\\1/"`
    UUID_DEV_PROVISION=${uuid_dev:16}
    echo 'UUID_DEV_PROVISION='${UUID_DEV_PROVISION}

    local uuid_inhouse_str=`grep -a ${KEY} -A1 ${FILE_INHOUSE_PROVISION}`
    local uuid_inhouse=`echo ${uuid_inhouse_str} | sed -E "s/\\<string\\>(.*)\\<\\/string\\>/\\1/"`
    UUID_INHOUSE_PROVISION=${uuid_inhouse:16}
    echo 'UUID_INHOUSE_PROVISION='${UUID_INHOUSE_PROVISION}
}

#导入描述文件，重命名为uuid，并复制到~/Library/MobileDevice/Provisioning\ Profiles/
function import_provision_file()
{
    echo "import_provision_file..."
    if [ ${UUID_DEV_PROVISION} == "0" ];
    then
       	echo "error UUID_DEV_PROVISION"
    else
       	echo "copy file ${FILE_DEV_PROVISION} to ${PATH_PROFILES}${UUID_DEV_PROVISION}.mobileprovision"
       	cp ${FILE_DEV_PROVISION} "${PATH_PROFILES}"${UUID_DEV_PROVISION}.mobileprovision
    fi

    if [ ${UUID_INHOUSE_PROVISION} == "0" ];
    then
        echo "error UUID_INHOUSE_PROVISION"
    else
        echo "copy file ${FILE_INHOUSE_PROVISION} to ${PATH_PROFILES}${UUID_INHOUSE_PROVISION}.mobileprovision"
       	cp ${FILE_INHOUSE_PROVISION} "${PATH_PROFILES}"${UUID_INHOUSE_PROVISION}.mobileprovision
    fi 
}

#修改project.pbxproj配置
function modify_pbxproj()
{
    echo "modify_pbxproj"

    cp -f ${FILE_PBXPROJ} ${FILE_PBXPROJ}.backup

    #找到PROVISIONING_PROFILE所在的行号；存放在array_provision_lines
    echo "find the line number of PROVISIONING_PROFILE"

    provision_str=`cat ${FILE_PBXPROJ} | grep -n "PROVISIONING_PROFILE"`
    declare -a array_provision_lines
    declare -a array_provision_strs
    i=1
    while((1==1))
    do
	split=`echo ${provision_str} | cut -d ";" -f${i}`
	if [ "${split}" != "" ]
	then
	    array_provision_lines[${i}]=`echo ${split// } | cut -d ":" -f1`
	    echo "${i}:${array_provision_lines[${i}]}"
	    array_provision_strs[${i}]=`echo ${split// } | sed -E "s/.*=+.*\\"([^\\"]*)\\"/\\1/"`
	    echo "${i}:${array_provision_strs[${i}]}" 
	    ((i++))
	else
	    break
	fi
    done

    #找到"\/\* Debug \*\/ = {"的行号
    echo "find the line number of \/\* Debug \*\/ = {"
    debug_str=`grep "\\\/\\\* Debug \\\*\\\/ = {" -n "${FILE_PBXPROJ}"`
    declare -a array_debug_lines
#    array_debug_lines_index=1
    echo "debug_str:\n${debug_str}"

#    out=`echo "${debug_str}" | awk '{split($0,a,"{");print a[1]'`
#    harf=$[${#debug_str}-1]

    harf=`expr ${#debug_str} / 2`
#    echo ${harf}
    debug_line1=`echo "${debug_str:0:${harf}}"`
    debug_line2=`echo "${debug_str:${harf}+1}"`

    
    array_debug_lines[1]=`echo "${debug_line1}" | cut -d ":" -f1`
    array_debug_lines[2]=`echo "${debug_line2}" | cut -d ":" -f1`
    echo 'array_debug_lines[1]='"${array_debug_lines[1]}"
    echo 'array_debug_lines[2]='"${array_debug_lines[2]}" 

    #找到"\/\* Release \*\/ = {"的行号
    echo "find the line number of \/\* Release \*\/ = {"
    release_str=`grep "\\\/\\\* Release \\\*\\\/ = {" -n "${FILE_PBXPROJ}"`
    declare -a array_release_lines
    #    array_release_lines_index=1
    echo "release_str:\n${release_str}"

    #    out=`echo "${release_str}" | awk '{split($0,a,"{");print a[1]'`
    #    harf=$[${#release_str}-1]

    harf=`expr ${#release_str} / 2`
    #    echo ${harf}
    release_line1=`echo "${release_str:0:${harf}}"`
    release_line2=`echo "${release_str:${harf}+1}"`


    array_release_lines[1]=`echo "${release_line1}" | cut -d ":" -f1`
    array_release_lines[2]=`echo "${release_line2}" | cut -d ":" -f1`
    echo 'array_release_lines[1]='"${array_release_lines[1]}"
    echo 'array_release_lines[2]='"${array_release_lines[2]}"   
    
    #根据array_debug_lines 和array_release_lines以及array_provision_lines判断修改的类型（Debug或Release）
    if [ ${array_debug_lines[1]} -lt ${array_release_lines[1]} ];
    then
	echo 'array_debug_lines[1] < array_release_lines[1]'
	tag_index=0
	for provision_line in ${array_provision_lines[@]}
	do
	    ((tag_index++))
	    if [ ${provision_line} -gt ${array_debug_lines[1]} -a ${provision_line} -lt ${array_release_lines[1]} ];
	    then
		#找到了debug对应的provision值所在的行
		echo "line:${provision_line} is provision_line for Debug"
		if [ ${UUID_DEV_PROVISION}  == "0" ];
		then
		    echo 'error UUID_DEV_PROVISION'
		else
		    echo "replease "${array_provision_strs[tag_index]}" with "${UUID_DEV_PROVISION}
		    #sed -i "" "s/${array_provision_strs[tag_index]}/${UUID_DEV_PROVISION}/g" ${FILE_PBXPROJ}
		    #sed -i -E "" '${provision_line}s/= "= [^"]*"/= "${UUID_DEV_PROVISION}"/g' ${FILE_PBXPROJ}
		    sed -i "" -E "${provision_line}s/= \"[^\"]*\"/= \"${UUID_DEV_PROVISION}\"/g" ${FILE_PBXPROJ}
		    
		    next_line_index=`expr ${tag_index} + 1`
		    next_line_str=`expr ${provision_line} + 1`
		    
		    if [ ${next_line_str} -eq ${array_provision_lines[${next_line_index}]} ];
		    then
			echo "line:${next_line_str} is provision_line for Debug too"
			sed -i "" -E "${next_line_str}s/= \"[^\"]*\"/= \"${UUID_DEV_PROVISION}\"/g" ${FILE_PBXPROJ}
		    else
			echo "line:${next_line_str} is not provision_line for Debug"
		    fi
		fi
		break
	    fi
	done

	tag_index=0
    	for provision_line in ${array_provision_lines[@]}
      	do
      	    ((tag_index++))
       	    if [ ${provision_line} -gt ${array_release_lines[1]} ];
	    then
		#找到了release对应的provision值所在的行
		echo "line:${provision_line} is provision_line for Release"
		if [ ${UUID_INHOUSE_PROVISION}  == "0" ];
		then
		    echo 'error UUID_INHOUSE_PROVISION'
		else
		    echo "replease "${array_provision_strs[tag_index]}" with "${UUID_INHOUSE_PROVISION}
		    #sed -i "" "s/${array_provision_strs[tag_index]}/${UUID_INHOUSE_PROVISION}/g" ${FILE_PBXPROJ}

		    sed -i "" -E "${provision_line}s/= \"[^\"]*\"/= \"${UUID_INHOUSE_PROVISION}\"/g" ${FILE_PBXPROJ}

		    next_line_index=`expr ${tag_index} + 1`
		    next_line_str=`expr ${provision_line} + 1`

		    if [ ${next_line_str} -eq ${array_provision_lines[${next_line_index}]} ];
		    then
			echo "line:${next_line_str} is provision_line for Release too"
			sed -i "" -E "${next_line_str}s/= \"[^\"]*\"/= \"${UUID_INHOUSE_PROVISION}\"/g" ${FILE_PBXPROJ}
		    else
			echo "line:${next_line_str} is not provision_line for Release"
		    fi  
		fi
		break
	    fi
	done
    else
	echo 'array_debug_lines[1] > array_release_lines[1]'
       	tag_index=0

       	for provision_line in ${array_provision_lines[@]}
       	do
       	    ((tag_index++))
       	    if [ ${provision_line} -gt ${array_release_lines[1]} -a ${provision_line} -lt ${array_debug_lines[1]} ];
       	    then
       	       	#找到了release对应的provision值所在的行
		echo "line:${provision_line} is provision_line for Release"
		if [ ${UUID_INHOUSE_PROVISION}  == "0" ];
		then
		    echo 'error UUID_INHOUSE_PROVISION'
		else
		    echo "replease "${array_provision_strs[tag_index]}" with "${UUID_INHOPUSE_PROVISION}
		    #sed -i "" "s/${array_provision_strs[tag_index]}/${UUID_INHOUSE_PROVISION}/g" ${FILE_PBXPROJ}
		    sed -i "" -E "${provision_line}s/= \"[^\"]*\"/= \"${UUID_INHOUSE_PROVISION}\"/g" ${FILE_PBXPROJ}

		    next_line_index=`expr ${tag_index} + 1`
		    next_line_str=`expr ${provision_line} + 1`

		    if [ ${next_line_str} -eq ${array_provision_lines[${next_line_index}]} ];
		    then
			echo "line:${next_line_str} is provision_line for Release too"
			sed -i "" -E "${next_line_str}s/= \"[^\"]*\"/= \"${UUID_INHOUSE_PROVISION}\"/g" ${FILE_PBXPROJ}
		    else
			echo "line:${next_line_str} is not provision_line for Release"
		    fi 
		fi
		break
	    fi
	done

	tag_index=0
	for provision_line in ${array_provision_lines[@]}
       	do
       	    ((tag_index++))
       	    if [ ${provision_line} -gt ${array_debug_lines[1]} ];
       	    then
      		#找到了debug对应的provision值所在的行
	      	echo "line:${provision_line} is provision_line for Debug"
	      	if [ ${UUID_DEV_PROVISION}  == "0" ];
       		then
       		    echo 'error UUID_DEV_PROVISION'
       		else
       		    echo "replease "${array_provision_strs[tag_index]}" with "${UUID_DEV_PROVISION}
	       	    #sed -i "" "s/${array_provision_strs[tag_index]}/${UUID_DEV_PROVISION}/g" ${FILE_PBXPROJ}
			sed -i "" -E "${provision_line}s/= \"[^\"]*\"/= \"${UUID_DEV_PROVISION}\"/g" ${FILE_PBXPROJ}
		    
		    next_line_index=`expr ${tag_index} + 1`
		    next_line_str=`expr ${provision_line} + 1`
		    
		    if [ ${next_line_str} -eq ${array_provision_lines[${next_line_index}]} ];
		    then
			echo "line:${next_line_str} is provision_line for Debug too"
			sed -i "" -E "${next_line_str}s/= \"[^\"]*\"/= \"${UUID_DEV_PROVISION}\"/g" ${FILE_PBXPROJ}
		    else
			echo "line:${next_line_str} is not provision_line for Debug"
		    fi
		fi 
	       	break
       	    fi
	done
    fi
    

    if [ ${array_debug_lines[2]} -lt ${array_release_lines[2]} ];
    then
	echo 'array_debug_lines[2] < array_release_lines[2]'
	tag_index=0
	for provision_line in ${array_provision_lines[@]}
	do
	    ((tag_index++))
	    if [ ${provision_line} -gt ${array_debug_lines[2]} -a ${provision_line} -lt ${array_release_lines[2]} ];
	    then
		#找到了debug对应的provision值所在的行
		echo "line:${provision_line} is provision_line for Debug"
		if [ ${UUID_DEV_PROVISION}  == "0" ];
		then
		    echo 'error UUID_DEV_PROVISION'
		else
		    echo "replease "${array_provision_strs[tag_index]}" with "${UUID_DEV_PROVISION}
		    #sed -i "" "s/${array_provision_strs[tag_index]}/${UUID_DEV_PROVISION}/g" ${FILE_PBXPROJ}
		    #sed -i -E "" '${provision_line}s/= "= [^"]*"/= "${UUID_DEV_PROVISION}"/g' ${FILE_PBXPROJ}
		    sed -i "" -E "${provision_line}s/= \"[^\"]*\"/= \"${UUID_DEV_PROVISION}\"/g" ${FILE_PBXPROJ}
        
		    next_line_index=`expr ${tag_index} + 1`
		    next_line_str=`expr ${provision_line} + 1`
        
		    if [ ${next_line_str} -eq ${array_provision_lines[${next_line_index}]} ];
		    then
			echo "line:${next_line_str} is provision_line for Debug too"
			sed -i "" -E "${next_line_str}s/= \"[^\"]*\"/= \"${UUID_DEV_PROVISION}\"/g" ${FILE_PBXPROJ}
		    else
			echo "line:${next_line_str} is not provision_line for Debug"
		    fi
		fi
		break
	    fi
	done

	tag_index=0
	for provision_line in ${array_provision_lines[@]}
        do
            ((tag_index++))
            if [ ${provision_line} -gt ${array_release_lines[2]} ];
	    then
		#找到了release对应的provision值所在的行
		echo "line:${provision_line} is provision_line for Release"
		if [ ${UUID_INHOUSE_PROVISION}  == "0" ];
		then
		    echo 'error UUID_INHOUSE_PROVISION'
		else
		    echo "replease "${array_provision_strs[tag_index]}" with "${UUID_INHOUSE_PROVISION}
		    #sed -i "" "s/${array_provision_strs[tag_index]}/${UUID_INHOUSE_PROVISION}/g" ${FILE_PBXPROJ}

		    sed -i "" -E "${provision_line}s/= \"[^\"]*\"/= \"${UUID_INHOUSE_PROVISION}\"/g" ${FILE_PBXPROJ}

		    next_line_index=`expr ${tag_index} + 1`
		    next_line_str=`expr ${provision_line} + 1`

		    if [ ${next_line_str} -eq ${array_provision_lines[${next_line_index}]} ];
		    then
			echo "line:${next_line_str} is provision_line for Release too"
			sed -i "" -E "${next_line_str}s/= \"[^\"]*\"/= \"${UUID_INHOUSE_PROVISION}\"/g" ${FILE_PBXPROJ}
		    else
			echo "line:${next_line_str} is not provision_line for Release"
		    fi  
		fi
		break
	    fi
	done
    else
	echo 'array_debug_lines[2] > array_release_lines[2]'
        tag_index=0

        for provision_line in ${array_provision_lines[@]}
        do
            ((tag_index++))
            if [ ${provision_line} -gt ${array_release_lines[2]} -a ${provision_line} -lt ${array_debug_lines[2]} ];
            then
                #找到了release对应的provision值所在的行
		echo "line:${provision_line} is provision_line for Release"
		if [ ${UUID_INHOUSE_PROVISION}  == "0" ];
		then
		    echo 'error UUID_INHOUSE_PROVISION'
		else
		    echo "replease "${array_provision_strs[tag_index]}" with "${UUID_INHOPUSE_PROVISION}
		    #sed -i "" "s/${array_provision_strs[tag_index]}/${UUID_INHOUSE_PROVISION}/g" ${FILE_PBXPROJ}
			sed -i "" -E "${provision_line}s/= \"[^\"]*\"/= \"${UUID_INHOUSE_PROVISION}\"/g" ${FILE_PBXPROJ}

		    next_line_index=`expr ${tag_index} + 1`
		    next_line_str=`expr ${provision_line} + 1`

		    if [ ${next_line_str} -eq ${array_provision_lines[${next_line_index}]} ];
		    then
			echo "line:${next_line_str} is provision_line for Release too"
			sed -i "" -E "${next_line_str}s/= \"[^\"]*\"/= \"${UUID_INHOUSE_PROVISION}\"/g" ${FILE_PBXPROJ}
		    else
			echo "line:${next_line_str} is not provision_line for Release"
		    fi  
		fi
		break
	    fi
	done

	tag_index=0
	for provision_line in ${array_provision_lines[@]}
        do
            ((tag_index++))
            if [ ${provision_line} -gt ${array_debug_lines[1]} ];
            then
		#找到了debug对应的provision值所在的行
		echo "line:${provision_line} is provision_line for Debug"
		if [ ${UUID_DEV_PROVISION}  == "0" ];
		then
		    echo 'error UUID_DEV_PROVISION'
		else
		    echo "replease "${array_provision_strs[tag_index]}" with "${UUID_DEV_PROVISION}
		    #sed -i "" "s/${array_provision_strs[tag_index]}/${UUID_DEV_PROVISION}/g" ${FILE_PBXPROJ}
		    sed -i "" -E "${provision_line}s/= \"[^\"]*\"/= \"${UUID_DEV_PROVISION}\"/g" ${FILE_PBXPROJ}
		    
		    next_line_index=`expr ${tag_index} + 1`
		    next_line_str=`expr ${provision_line} + 1`
		    
		    if [ ${next_line_str} -eq ${array_provision_lines[${next_line_index}]} ];
		    then
			echo "line:${next_line_str} is provision_line for Debug too"
			sed -i "" -E "${next_line_str}s/= \"[^\"]*\"/= \"${UUID_DEV_PROVISION}\"/g" ${FILE_PBXPROJ}
		    else
			echo "line:${next_line_str} is not provision_line for Debug"
		    fi
		fi 
		break
            fi
	done
    fi
    
    #sed -i "" "s/PROVISIONING_PROFILE = \"[^\"]*\";/PROVISIONING_PROFILE = \"${UUID_DEV_PROVISION}\";/g" ${FILE_PBXPROJ}
    #sed -i "" "s/PROVISIONING_PROFILE = \"[^\"]*\";/PROVISIONING_PROFILE = \"${UUID_DEV_PROVISION}\";/g" ${FILE_PBXPROJ}
    

    echo "cat ${FILE_PBXPROJ}.backup | grep PROVISIONING_PROFILE  ===>"
    cat ${FILE_PBXPROJ}.backup | grep -n PROVISIONING_PROFILE
    echo "                       ||                       "
    echo "                       ||                       "
    echo "                       ||                       "
    echo "                       \/                       "
    echo "cat ${FILE_PBXPROJ} | grep PROVISIONING_PROFILE  ===>"
    cat ${FILE_PBXPROJ} | grep -n PROVISIONING_PROFILE

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
		echo "UUID_DEV_PROVISION=${UUID_DEV_PROVISION}"
		;;
	    r)
		#release_mobileprovision文件全路径
		FILE_INHOUSE_PROVISION=${OPTARG}
		echo "UUID_INHOUSE_PROVISION=${UUID_INHOUSE_PROVISION}"
		;;
	    \?)
		echo "no match the opt:$opt"
		usage
		exit 1
		;;
	esac	
    done

    if [ "${PATH_PBXPROJ}" == "" -a "${FILE_PBXPROJ}" == "" ];then
	usage "Need -P to set project path or -p to set pbxproj file."
	exit 1
    fi

    if [ "${PATH_PROVISION}" == "" ] && [ "${UUID_DEV_PROVISION}" == "" -o "${UUID_INHOUSE_PROVISION}" == "" ];then
       usage "Need -D to set mobileprovision directory or -d -r to set mobileprovision file"
       exit 1
    fi    
}

function init()
{
    parser_args $@
}


main()
{
    init $@
    get_uuid
    import_provision_file
    modify_pbxproj
}

main $@
