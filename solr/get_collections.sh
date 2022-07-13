# This query will get all Collections entries

curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?q=has_model_ssim:**Collection**\&rows=999999999\&wt=csv --output all_collections.csv
