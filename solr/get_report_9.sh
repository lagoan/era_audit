
# Authenticated items
curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id,%20visibility_after_embargo_ssim,%20embargo_end_date_dtsi\&indent=on\&q=has_model_ssim:**Item**%20AND%20visibility_ssim:%22http://terms.library.ualberta.ca/embargo%22\&rows=999999999\&wt=csv --output reports/report_9_items.csv

# Authenticated theses
curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id,%20visibility_after_embargo_ssim,%20embargo_end_date_dtsi\&indent=on\&q=has_model_ssim:**Thesis**%20AND%20visibility_ssim:%22http://terms.library.ualberta.ca/embargo%22\&rows=999999999\&wt=csv --output reports/report_9_thesis.csv


