# This query will get all Communities entries

curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2/select?q=has_model_ssim:**Community**\&rows=999999999\&wt=csv --output all_communities.csv
