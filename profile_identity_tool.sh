#!bin/bash
cd "$(dirname "$0")"
#Global define
PATH_PROJECT="."
PATH_PROVISION="."

FILE_PBXPROJ=""
FILE_DEBUG_PROVISION=""
FILE_RELEASE_PROVISION=""

#用法简介
function usage()
{
    if [ $# -gt 0 ];then
	echo "Error: $@"
    fi
    echo "usage:sh profile_identity_tool.sh [-P projectdir] [-D provisiondir] [-p pbxprojfile] [-d debufile] [-r release file]"
    echo "if -p , -P is nouse;if -d and -r ,-D is nouse"
    echo "-P set project dir."
    echo "-D set mobileprovision dir"
    echo "-p set pbxproj file"
    echo "-d set debug mobileprovision file"
    echo "-r set release mobileprovision file"
}

#参数解析
function parser_args()
{
    while getopts hP:D:p:d:r: opt
    do
	case "$opt" in
	    h)
		#帮助
		usage
		;;
	    P)
		#设置工程路径目录
		PATH_PROJECT=$OPTARG
		echo "PATH_PROJECT=${PATH_PROJECT}"
		;;
	    D)
		#设置mobileprovision文件路径目录
		PATH_PROVISION=${OPTARG}
		echo "PATH_PROVISION=${PATH_PROVISION}"
		;;
	    p)
		#pbxproj文件全路径
		FILE_PBXPROJ=$OPTARG
		echo "FILE_PBXPROJ=${FILE_PBXPROJ}"
		;;
	    d)
		#debug_mobileprovision文件全路径
		FILE_DEBUG_PROVISION=$OPTARG
		echo "FILE_DEBUG_PROVISION=${FILE_DEBUG_PROVISION}"
		;;
	    r)
		#release_mobileprovision文件全路径
		FILE_RELEASE_PROVISION=${OPTARG}
		echo "FILE_RELEASE_PROVISION=${FILE_RELEASE_PROVISION}"
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

    if [ "${PATH_PROVISION}" == "" ] && [ "${FILE_DEBUG_PROVISION}" == "" -o "${FILE_RELEASE_PROVISION}" == "" ];then
       usage "Need -D to set mobileprovision directory or -d -r to set mobileprovision file"
       exit 1
    fi
}


#根据输入的工程目录，获取pbxproj文件的全路径
function get_pbxproj_by_prj()
{
    project_dir=${PATH_PROJECT}
    if [ $1_ != ""_ ];then
	project_dir=$1
    fi
    if [ ${project_dir} != "" ];then
	file_xcodeproj=`ls "${project_dir}" | grep "xcodeproj$"`
	path_xcodeproj=`echo "${project_dir}"/${file_xcodeproj}`
	
	FILE_PBXPROJ=`echo "${path_xcodeproj}/project.pbxproj"`
	echo "FILE_PBXPROJ=${FILE_PBXPROJ}"
    fi
}

#根据输入的mobileprovision文件路径目录，选择Debug和Release描述文件
function get_provision()
{
    provision_dir=${PATH_PROVISION}
    if [ $1_ != ""_ ];then
	provision_dir=$1
    fi
    if [ ${provision_dir} != "" ];then
	provision_str=`ls "${provision_dir}" | grep "mobileprovision$"`
	echo "provision_str:${provision_str}"
    fi

    i=1
    debug_file=""
    release_file=""
    while((1==1))
    do
	split=`echo ${provision_str} | cut -d " " -f${i}`
	if [ "${split}" != "" ];then
	    dev=`echo "${split// }" | grep "dev"`
	    inhouse=`echo "${split// }" | grep "inhouse"`
	    dis=`echo "${split// }" | grep "dis"`
	    if [ "${dev}" != "" ];then
		debug_file="${dev}"
	    fi
	    if [ "${inhouse}" != "" ];then
		release_file="${inhouse}"
	    fi
	    if [ "${dis}" != "" ];then
		release_file="${dis}"
	    fi
	    ((i++))
	else
	    break
	fi
    done
    FILE_DEBUG_PROVISION="${provision_dir}/${debug_file}"
    FILE_RELEASE_PROVISION="${provision_dir}/${release_file}"
    if [ "${debug_file}" == "" ];then
	FILE_DEBUG_PROVISION="${provision_dir}/${release_file}"
    fi

    if [ "${release_file}" == "" ];then
	FILE_DEBUG_PROVISION="${provision_dir}/${debug_file}"
    fi

    if [ "${debug_file}" == "" -a "${release_file}" == "" ];then
	echo "not found provision file in ${provision_dir}"
	exit 1
    else	
	echo "FILE_DEBUG_PROVISION:\n${FILE_DEBUG_PROVISION}"
	echo "FILE_RELEASE_PROVISION:\n${FILE_RELEASE_PROVISION}"
    fi
}



#导入描述文件，并修改工程
function modify_pbxproj()
{
    if [ "${FILE_PBXPROJ}" != "" -a "${FILE_DEBUG_PROVISION}" != "" -a "${FILE_RELEASE_PROVISION}" != "" ];then
	sh ./provisionhelper.sh -p "${FILE_PBXPROJ}" -d "${FILE_DEBUG_PROVISION}" -r "${FILE_RELEASE_PROVISION}"
	sh ./identityhelper.sh -p "${FILE_PBXPROJ}" -d "${FILE_DEBUG_PROVISION}" -r "${FILE_RELEASE_PROVISION}"
    else
	echo "pbxproj fille or mobileprovision file error"
    fi
}

main()
{
    parser_args $@
    if [ "${FILE_PBXPROJ}" == "" ];then
	get_pbxproj_by_prj ""
    fi
    if [ "${FILE_DEBUG_PROVISION}" == "" -o "${FILE_RELEASE_PROVISION}" == "" ];then
	get_provision ""
    fi
    modify_pbxproj
}

main $@
