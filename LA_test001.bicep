param logic_app_name string = 'LA_CON_DevOps_test'
param loaction string = resourcesgroupe().location

resource workflows_GMCLA001_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logic_app_name
  location: location
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
      triggers: {}
      actions: {}
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {}
      }
    }
  }
}
