#!/bin/bash
#!/bin/bash
# 利用 Liquibase 进行数据库表结构的管理
# 通过检测源码目录下指定文件夹下的 changelog 文件，来决定是否准备 Liquibase 环境
# Liquibase 的运行需要 java 环境支持，指定的 connector jar 包
# 目前仅支持 Mysql 类型数据库的对接

function detectSqlControl() {
    local schema_dir=$1
    # skip schema version control without  schema dir
    if [ ! -d $schema_dir ]; then
        return 0
    fi
    # cd schema dir
    pushd $schema_dir >/dev/null
    # find *.properties in schema dir
    # deal with every properties file
    for config_file in $(ls *.properties); do
        info "=== Database version control file $config_file has been found ==="
        dealWithConfig $config_file
        runLiquiCmd $config_file || continue
    done
    popd >/dev/null
}

function dealWithConfig() {
    # Checks whether a configuration file exists named liquibase.properties
    # Render the template configuration file using environment variables
    # Currently, only mysql is supported
    local config_file=$1
    info "Customing liquibase config file $config_file"
    # Just skip login liquibase hub cloud service
    if ! (grep "liquibase.hub.mode*" $config_file >/dev/null); then
        echo "liquibase.hub.mode=off" >>$config_file
    fi
    envToConfig $config_file
}

function runLiquiCmd() {
    local config_file=$1
    # Checks change sets before update
    # If there is no Changeset to be executed, do not update
    local log_file=$config_file.log
    # run liquibase status, log to temp file
    liquibase status --defaults-file=$config_file &>$log_file
    if [[ $? != 0 ]]; then
        warn "Failed to check the database status. Check $schema_dir/$log_file"
        return 1
    fi
    grep "change sets have not been applied to" $log_file >/dev/null
    if [[ $? == 0 ]]; then
        info "Updating change sets to db which defined by $config_file..."
        liquibase update --defaults-file=$config_file &>$log_file
        [[ $? == 0 ]] && info "Updated with $config_file successfully!" || warn "Failed to upgrade the database schema. Check $schema_dir/$log_file"
    else
        info "No change set was found to be executed, skiping..."
    fi
}

function envToConfig() {
    # which file should be rendered by envrionment variables
    local config_file=$1
    # get every envrionment variable's name
    defined_envs=$(printf '${%s} ' $(env | cut -d= -f1))
    # make template file for config file
    cp $config_file $config_file.tmp
    # render config file
    info "Rendering $config_file using environment variables"
    cat $config_file.tmp | envsubst "$defined_envs" >$config_file
    # remove template file
    rm $config_file.tmp
}
