# This query gets all thesis entries
curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2/select?q=has_model_ssim:**Thesis**\&rows=999999999\&wt=csv --output reports/report_11.csv