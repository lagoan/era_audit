
# # Authenticated items
# curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id\&q=has_model_ssim:**Item**%20AND%20visibility_ssim:http://terms.library.ualberta.ca/authenticated\&rows=999999999\&wt=csv --output reports/report_8_items.csv

# # Authenticated theses
# curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id\&q=has_model_ssim:**Thesis**%20AND%20visibility_ssim:http://terms.library.ualberta.ca/authenticated\&rows=999999999\&wt=csv --output reports/report_8_thesis.csv


# Authenticated items
# curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?& fl=id\&q=has_model_ssim:**Item**%20AND%20visibility_ssim:http://terms.library.ualberta.ca/authenticated\&rows=999999999\&wt=csv --output reports/report_8_items.csv
curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id\&q=has_model_ssim:**Item**%20AND%20visibility_ssim:%22http://terms.library.ualberta.ca/authenticated%22\&rows=999999999\&wt=csv --output reports/report_8_items.csv

# Authenticated theses
# curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id\&q=has_model_ssim:**Thesis**%20AND%20visibility_ssim:http://terms.library.ualberta.ca/authenticated\&rows=999999999\&wt=csv --output reports/report_8_thesis.csv
curl http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id\&q=has_model_ssim:**Thesis**%20AND%20visibility_ssim:%22http://terms.library.ualberta.ca/authenticated%22\&rows=999999999\&wt=csv --output reports/report_8_thesis.csv