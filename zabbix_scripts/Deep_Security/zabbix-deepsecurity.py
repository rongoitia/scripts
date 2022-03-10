import deepsecurity as api
from deepsecurity.rest import ApiException as api_exception


def get_policies_list(api, configuration, api_version, api_exception):
    """ Gets a list of policies on the Deep Security Manager

    :return: A PoliciesApi object that contains a list of policies.
    """

    # Create a PoliciesApi object
    policies_api = api.PoliciesApi(api.ApiClient(configuration))

    # List policies using version v1 of the API
    policies_list = policies_api.list_policies(api_version)

    # View the list of policies
    return policies_list


if __name__ == '__main__':
    # Add Deep Security Manager host information to the api client configuration
    configuration = api.Configuration()
    configuration.host = 'https://10.0.201.162:4119/api'

    # Authentication
    configuration.api_key['api-secret-key'] = 'api-secret-key'

    # Version
    api_version = 'v1'
    a_file = open("sample.txt", "w")
    print(get_policies_list(api, configuration, api_version, api_exception), file=a_file)
    a_file.close()

