#!/bin/bash

ENV=$1                    
baktime=$(date +%Y%m%d)    
tables="Table_Name Table_Name1 Table_Name3"
tenants="tenant1 tenant2 tenant3 tenant4 tenant5 tenant7"

for table in $tables; do
    for tenant_id in $tenants; do
        NumOfRaw=$(bq show --format=prettyjson project-${ENV}:${tenant_id}_analytics.${table} | jq -r '.numRows')
        if [ $NumOfRaw == "0" ]; then
            echo "Table project-${ENV}:${tenant_id}_analytics.${table} do not have any data."
            echo "no data project-${ENV}:${tenant_id}_analytics.${table}" >> no-data-${ENV}.txt
        else
            echo "Creating backup for project-${ENV}:${tenant_id}_analytics.${table}..."
            bq cp --clone --no_clobber project-${ENV}:${tenant_id}_analytics.${table} project-${ENV}:${tenant_id}_analytics.${table}_bak${baktime}
            echo "project-${ENV}:${tenant_id}_analytics.${table}_bak${baktime}" >> backups-${ENV}-prefix.txt
            echo "backuped project-${ENV}:${tenant_id}_analytics.${table}" >> backups-${ENV}-${tenants}.txt
        fi
    done
done
