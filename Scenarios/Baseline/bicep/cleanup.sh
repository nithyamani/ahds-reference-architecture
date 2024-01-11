# Full Cleanup
# Delete Resource Groups
az group delete -n ent-dev-fhir-rg -y --no-wait
az group delete -n NetworkWatcherRG -y --no-wait
# Make sure you get the right APIM and replace it
az apim deletedservice purge --service-name ent-dev-fhir-apim-s2o27vtyq5r36 --location EastUS
# Delete Deployments
az deployment sub delete -n ent-dev-fhir-ahds --no-wait
az deployment sub delete -n ent-dev-fhir-network --no-wait