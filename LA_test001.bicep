param logic_app_name string = 'LA_CON_DevOps_Test001'
param location string = resourceGroup().location
param connections_office365_externalid string = '/subscriptions/ff832265-8dfd-4ba5-8120-532bc89348ef/resourceGroups/GM-LA-CON/providers/Microsoft.Web/connections/office365'

resource workflows_GMCLA001_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_GMCLA001_name
  location: 'northcentralus'
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      staticResults: {
        Send_approval_email0: {
          status: 'Succeeded'
          outputs: {
            statusCode: 'OK'
            body: {
              SelectedOption: 'Approve'
            }
          }
          hasDelegate: false
        }
      }
      triggers: {
        When_a_HTTP_request_is_received: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              method: 'POST'
              uri: 'https://api.contoso.com/jobs'
              headers: {
                'Content-Type': 'application/json'
                Authorization: 'Bearer '
              }
              body: {
                folder: 'ABC'
                jobId: '12345'
                jobType: 'create'
                description: 'Initiate job for data processing'
                priority: 'high'
                metadata: {
                  createdBy: 'Girish Kumar Mallula'
                  department: 'IT'
                  timestamp: '2025-06-23T12:40:00Z'
                }
              }
            }
          }
        }
      }
      actions: {
        Response: {
          runAfter: {
            'Send_an_email_(V2)': [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 200
          }
        }
        'Send_an_email_(V2)': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: {
              To: 'v-gmallula@microsoft.com'
              Subject: 'test'
              Body: '<p class="editor-paragraph">Hello</p>'
              Importance: 'Normal'
            }
            path: '/v2/Mail'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          office365: {
            id: '/subscriptions/ff832265-8dfd-4ba5-8120-532bc89348ef/providers/Microsoft.Web/locations/northcentralus/managedApis/office365'
            connectionId: connections_office365_externalid
            connectionName: 'office365'
          }
        }
      }
    }
  }
}



var cosmosdb_connection_name = 'CosmosDB'
var commondataservice_recource_providerid = '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/documentdb'

resource cosmosdb_account 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: toLower(cosmosdb_account_name)
}

resource connection_cosmosdb 'Microsoft.Web/connections@2016-06-01' = {
  name: cosmosdb_connection_name
  location: location
  kind: 'V1'
  properties: {
    displayName: 'CosmosDB-Connection'
    statuses: [
      {
        status: 'Connected'
      }
    ]
    parameterValues: {
      databaseAccount: cosmosdb_account.name
      accessKey: cosmosdb_account.listKeys().primaryMasterKey
    }
    api: {
      id: commondataservice_recource_providerid
    }
  }
}

resource workflows_la_cms_integraiton_002_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logic_app_name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                address: {
                  properties: {
                    addressLine1: {
                      type: 'string'
                    }
                    city: {
                      type: 'string'
                    }
                    postcode: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                contactPerson: {
                  type: 'string'
                }
                contactPhone: {
                  type: 'string'
                }
                customerName: {
                  type: 'string'
                }
                id: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Compose: {
          runAfter: {}
          type: 'Compose'
          inputs: {
            address: {
              city: '@triggerBody()?[\'address\']?[\'city\']'
              postCode: '@triggerBody()?[\'address\']?[\'postcode\']'
              street: '@triggerBody()?[\'address\']?[\'addressLine1\']'
            }
            externalId: '@triggerBody()?[\'id\']'
            id: '@guid()'
            name: '@triggerBody()?[\'customerName\']'
            primaryContact: {
              name: '@triggerBody()?[\'contactPerson\']'
              phone: '@triggerBody()?[\'contactPhone\']'
            }
          }
        }
        'Create_or_update_document_(V3)': {
          runAfter: {
            Compose: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: '@outputs(\'Compose\')'
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'documentdb\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/cosmosdb/@{encodeURIComponent(\'AccountNameFromSettings\')}/dbs/@{encodeURIComponent(\'CMS\')}/colls/@{encodeURIComponent(\'Customers\')}/docs'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          documentdb: {
            connectionId: connection_cosmosdb.id
            connectionName: connection_cosmosdb.name
            id: connection_cosmosdb.properties.api.id
          }
        }
      }
    }
  }
}
