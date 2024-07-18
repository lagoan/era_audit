# This query will get all FileSet entries to be used for reports where files need to be checked

# curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2/select?q=has_model_ssim:**FileSet**\&rows=999999999\&wt=csv --output all_filesets.csv
curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2/select?q=has_model_ssim:**IRFileSet**\&rows=999999999\&wt=csv --output all_filesets.csv
