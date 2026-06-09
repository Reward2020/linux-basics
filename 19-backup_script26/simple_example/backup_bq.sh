#!/bin/bash

ENV_LIST=$1 
copy_time=$(date +%Y%m%d)
tables="TABLE_name1 TABLE_name2 TABLE_name3 TABLE_name4 TABLE_name5"

case $ENV_LIST in
  "dev")
    TENANTS_LIST="tenant1 tenant2 tenant3 tenant4 tenant5 tenant6 tenant7"
    ;;
  "qa")
    TENANTS_LIST="tenant1 tenant2 tenant3 tenant4 tenant5 tenant6 tenant7 tenant8 tenant9 tenant10"
    ;;
  "intg")
    TENANTS_LIST="tenant1 tenant2 tenant3 tenant4 tenant5"
    ;;
  "test")
    TENANTS_LIST="tenant1 tenant2 tenant3 tenant4 tenant5 tenant6 tenant7 tenant8 tenant9 tenant10 tenant11 tenant12 tenant13 tenant14 tenant15"
    ;;
  "prod")
    TENANTS_LIST="tenant1 tenant2 tenant3 tenant4 tenant5 tenant6 tenant7 tenant8 tenant9 "
    ;;
  *)
    echo "Invalid environment specified $ENV_LIST"
    exit 1
    ;;
esac

for ENV in $ENV_LIST; do
    for table in $tables; do
        for tenant_id in $TENANTS_LIST; do
            table_full="your-project-${ENV}:${tenant_id}_analytics.${table}"
            if bq show --format=prettyjson "$table_full" > /dev/null 2>&1; then
                NumOfRaw=$(bq show --format=prettyjson "$table_full" | jq -r '.numRows // empty')
    
                if [[ -z "$NumOfRaw" ]]; then
                    echo "Cannot get numRows for $table_full"
                    echo "no data $table_full" >> no-data-${ENV}.txt
                elif [[ "$NumOfRaw" == "0" ]]; then
                    echo "Table $table_full does not have any data."
                    echo "no data $table_full" >> no-data-${ENV}.txt
                else
                    echo "Creating backup for $table_full..."
                    bq cp --clone --no_clobber "$table_full" "${table_full}_copy_${copy_time}"
                    echo "${table_full}_copy_${copy_time}" >> backups-${ENV}-prefix.txt
                    echo "backuped ${table_full}_copy_${copy_time}"
                fi
            else
                echo "Table $table_full not found."
                echo "not found $table_full" >> no-data-${ENV}.txt
            fi
        done
    done
done
