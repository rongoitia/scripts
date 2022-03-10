from __future__ import print_function
import sys, warnings
import deepsecurity
from deepsecurity.rest import ApiException
from pprint import pprint
import io

# Setup
if not sys.warnoptions:
	warnings.simplefilter("ignore")
configuration = deepsecurity.Configuration()
configuration.host = 'https://10.0.201.162:4119/api'

# Authentication
configuration.api_key['api-secret-key'] = 'api-secret-key'

# Initialization
# Set Any Required Values
api_instance = deepsecurity.EventBasedTasksApi(deepsecurity.ApiClient(configuration))
api_version = 'v1'

try:
	api_response = api_instance.list_event_based_tasks(api_version)
	pprint(api_response)
except ApiException as e:
	print("An exception occurred when calling EventBasedTasksApi.list_event_based_tasks: %s\n" % e)

