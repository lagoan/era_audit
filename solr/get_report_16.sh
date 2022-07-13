# has_model_ssim:IRCollection -description_tesim:["" TO *]
# curl -g http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id\&indent=on\&rows=999999999\&q=has_model_ssim:IRCollection%20-description_tesim:[%22%22%20TO%20*]\&wt=csv --output reports/report_16.csv

curl -g http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id\&indent=on\&q=has_model_ssim:**Collection**%20-description_tesim:\[%22%22%20TO%20*\]\&rows=99999\&wt=csv --output reports/report_16.csv