#!/bin/bash

###################
# Prompt and Validating Azure Region
###################
read -p "Inform Azure Region to be deployed? " answerAzRegion
azRegions=$(az account list-locations --query '[].name' -o tsv)
if [[ $azRegions == *$answerAzRegion* ]]; then
  echo "Azure Region found: $answerAzRegion"
else
  echo "Region $answerAzRegion Not found"
  echo ""
  echo "Use one of the available Azure Regions:"
  echo $azRegions
  exit;
fi

###################
# Prompt Azure Aplication Gateway FQDN
###################
read -p "Inform Azure Application Gateway FQDN? " answerAppGWFQDN
echo "Azure Aplication Gateway FQDN: $answerAppGWFQDN"

###################
# List of required azure providers
###################
azProviders=("Microsoft.Network" "Microsoft.Compute" "Microsoft.ContainerInstance" "Microsoft.KeyVault" "Microsoft.ManagedIdentity" "Microsoft.Storage" "Microsoft.HealthcareApis" "Microsoft.Diagnostics" "Microsoft.ContainerRegistry" "Microsoft.Web")

###################
# Checking if a required provider is not registered and save in array azProvidersNotRegistered
###################
azProvidersNotRegistered=()
for provider in "${azProviders[@]}"
do
  registrationState=$(az provider show --namespace $provider --query "[registrationState]" --output tsv)
  if [ "$registrationState" != "Registered" ]; then
    #echo "Found an Azure Resource Provider not registred: $provider"
    azProvidersNotRegistered+=($provider)
    #echo "${azProvidersNotRegistered[@]}"
  fi
done

###################
# Registering all missing required Azure providers
###################
if (( ${#azProvidersNotRegistered[@]} > 0 )); then
  echo "Registering required Azure Providers"
  echo ""
  for provider in "${azProvidersNotRegistered[@]}"
  do
    echo "Registering Azure Provider: $provider"
    az provider register --namespace $provider
  done
fi
echo ""

###################
# Function to remove an element of an array
###################
remove_array_element_byname(){
    index=0
    name=$1[@]
    param2=$2
    fun_arr=("${!name}")

    for element in "${fun_arr[@]}"
    do
      if [[ $element == $param2 ]]; then
        foundindex=$index
      fi
      index=$(($index + 1))
    done
    unset fun_arr[$foundindex]
    ret_val=("${fun_arr[@]}")
}

###################
# Checking the status of missing Azure Providers
###################
if (( ${#azProvidersNotRegistered[@]} > 0 )); then
  copy_azProvidersNotRegistered=("${azProvidersNotRegistered[@]}")
  while (( ${#copy_azProvidersNotRegistered[@]} > 0 ))
  do
    elementcount=0
    for provider in "${azProvidersNotRegistered[@]}"
    do
      registrationState=$(az provider show --namespace $provider --query "[registrationState]" --output tsv)
      if [ "$registrationState" != "Registered" ]; then
        echo "Waiting for Azure provider $provider ..."
      else
        echo "Azure provider $provider registered!"
        remove_array_element_byname copy_azProvidersNotRegistered $provider
        ret_remove_array_element_byname=("${ret_val[@]}")
        copy_azProvidersNotRegistered=("${ret_remove_array_element_byname[@]}")
      fi
    done
    azProvidersNotRegistered=("${copy_azProvidersNotRegistered[@]}")
    echo ""

    echo "Amount of providers waiting to be registered: ${#azProvidersNotRegistered[@]}"
    echo "Waiting 10 seconds to check the missing providers again"
    echo "############################################################"
    sleep 10
    clear
  done
  echo "Done registering required Azure Providers"
fi

# Network-LZ
fhirRGName=ent-dev-fhir-rg
apimRGName=ent-dev-apim-rg
az deployment sub create -n "ent-dev-fhir-network" -l $answerAzRegion -f Network-LZ/main.bicep -p Network-LZ/parameters-main.json -p fhirRGName=$fhirRGName -p apimRGName=$apimRGName

# AHDS
publicipappgw=$(az deployment sub create -n "ent-dev-fhir-ahds" -l $answerAzRegion -f AHDS/main.bicep -p AHDS/parameters-main.json -p fhirRGName=$fhirRGName  -p apimRGName=$apimRGName -p appGatewayFQDN=$answerAppGWFQDN --query "properties.outputs.publicipappgw.value" -o tsv)
echo "Please create a DNS record for the Application Gateway Public IP: $publicipappgw with the FQDN: $answerAppGWFQDN"
echo Done