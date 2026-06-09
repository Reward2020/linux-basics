#!/bin/bash
# Script to migrate table data across environments and tenants

ENV_LIST=$1
TABLE_LIST="TABLE_name1 TABLE_name2 TABLE_name3 TABLE_name4 TABLE_name5"
copy_time=$(date +%Y%m%d)

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
  for TENANT in $TENANTS_LIST; do
    for TABLE in $TABLE_LIST; do
      DATASET="your-project-${ENV}:${TENANT}_analytics"
      COPY_TABLE="${TENANT}_analytics.${TABLE}_copy_${copy_time}"

      # Перевірка існування датасету
      if bq show "$DATASET" &>/dev/null; then

        # Перевірка існування таблиці копії
        if bq show --format=none "${DATASET%:*}:$COPY_TABLE" &>/dev/null; then
          echo "Inserting data for $TENANT in $ENV ($TABLE)"
          sed "s/<env>/${ENV}/g; s/<tenant>/${TENANT}/g; s/<current_date>/${copy_time}/g" ${TABLE}.sql > temp_${TABLE}_${TENANT}_${ENV}.sql
          bq query --nouse_legacy_sql < temp_${TABLE}_${TENANT}_${ENV}.sql
          rm temp_${TABLE}_${TENANT}_${ENV}.sql
        else
          echo "Backup table not found for $TENANT in $ENV ($TABLE) — move to the next table."
        fi

      else
        echo -e "\n Dataset not found: your-project-${ENV}:${TENANT}_analytics"
        echo "Skipped $TABLE for $TENANT in $ENV"
      fi
    done
  done
done
