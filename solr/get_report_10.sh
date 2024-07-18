# This query gets all item entries
curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2/select?q=has_model_ssim:*Item*\&rows=999999999\&wt=csv --output reports/report_10.csv
