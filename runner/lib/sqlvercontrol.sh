#!/bin/bash
#!/bin/bash
# 利用 Liquibase 进行数据库表结构的管理
# 通过检测源码目录下指定文件夹下的 changelog 文件，来决定是否准备 Liquibase 环境
# Liquibase 的运行需要 java 环境支持，指定的 connector jar 包
# 目前仅支持 Mysql 类型数据库的对接

function detectSqlControl() {
    CHANGE_LOG_FILE=${CHANGE_LOG_FILE:-"rainsql/changelog.sql"}
    if [ -f $HOME/${CHANGE_LOG_FILE} ]; then
        info "Database version control file ${CHANGE_LOG_FILE} has been found..."
        dealWithConfig
        runLiquiCmd || return 0
    fi
}

function dealWithConfig() {
    # Checks whether a configuration file exists named liquibase.properties
    # Render the template configuration file using environment variables
    # Currently, only mysql is supported
    LIQUIBASE_CONFIG_FILE=${LIQUIBASE_CONFIG_FILE:-"rainsql/liquibase.properties"}
    if ! grep "__MYSQL_HOST__" $HOME/${LIQUIBASE_CONFIG_FILE} >/dev/null; then
        info "Useing custom liquibase config file ${LIQUIBASE_CONFIG_FILE}"
    elif [ ! -z $MYSQL_USER ] && [ ! -z $MYSQL_PASSWORD ] && [ ! -z $MYSQL_DATABASE ]; then
        info "Rendering ${LIQUIBASE_CONFIG_FILE} using environment variables"
        sed -i -e "s/__MYSQL_HOST__/${MYSQL_HOST:-127.0.0.1}/g" \
            -e "s/__MYSQL_PORT__/${MYSQL_PORT:-3306}/g" \
            -e "s/__MYSQL_USER__/${MYSQL_USER:-root}/g" \
            -e "s/__MYSQL_PASSWORD__/${MYSQL_PASSWORD:-""}/g" \
            -e "s/__MYSQL_DATABASE__/${MYSQL_DATABASE}/g" \
            -e "s/changelog.sql/${CHANGE_LOG_FILE#*/}/g" ${LIQUIBASE_CONFIG_FILE}
    else
        warn "Whether appropriate mysql connection environment variables have been defined?"
        warn "Declare \$MYSQL_USER \$MYSQL_PASSWORD \$MYSQL_HOST \$MYSQL_PORT \$MYSQL_DATABASE please."
    fi
}

function runLiquiCmd() {
    # Checks change sets before update
    # If there is no Changeset to be executed, do not update
    LIQUIBASE_TEMP_FILE=${LIQUIBASE_TEMP_FILE:-"rainsql/cmd.log"}
    # run liquibase status, log to temp file
    pushd ${CHANGE_LOG_FILE%/*}
    liquibase status &>$HOME/${LIQUIBASE_TEMP_FILE}
    grep "change sets have not been applied to" $HOME/${LIQUIBASE_TEMP_FILE} >/dev/null &&
        info "Updating change sets to db..." &&
        liquibase update &>$HOME/${LIQUIBASE_TEMP_FILE}
    [[ $? == 0 ]] && info "Updated successfully!"
    popd
}
