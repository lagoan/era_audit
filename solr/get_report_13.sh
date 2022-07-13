# has_model_ssim:IRCommunity -description_tesim:["" TO *]

curl -g http://solrcloud-prod.library.ualberta.ca:8080/solr/jupiter2_recovery_20201216/select?fl=id\&indent=on\&rows=999999999\&q=has_model_ssim:**Community**%20-description_tesim:[%22%22%20TO%20*]\&wt=csv --output reports/report_13.csv