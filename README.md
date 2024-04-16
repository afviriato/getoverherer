## This is a handy script to help us to use curl based in json configuration files and .env files as well

*The script's goal is to avoid boilerplate work that has been made when we need to create complexes curl commands to simple API requests.*

### Motivation
At some moment of our developers careers we need to use some tools to test our apis or even test someone elses.
The most commons tools that we can think about it is Postman or Insomnia. Those are wonderful tools no doubt about it but
all of those tools hidden some tricks like:
 - `Subscription`: Soner or later this "free" tools came to us with a free subscription to use basic resources
 - `Heavy`: This tools take a lot of RAM (and space in disk, by the away) to do basic tasks like send requests and get responses
 - `Slow`: Splash screens, welcome screens and stuff. This things are cool if you just start your developer career beside that its sucks.
 - `Tired`: I am tired of using these tools and wanted to write some bash scripts. That is it.

And the most important thing: Linux already has a lot of tools in its belt and if you are a Linux user you should take  advantage of this.
If you are not a Linux user, well, I am sorry for you. Just kidding.

### Script name
Just like the Scorpion send his kunai rope to bring his enemies near to him, this script send requests to get responses. So there are a best name for it?

### Dependencies
To run this script you just need:
 - [curl](https://curl.se)
 - [jq](https://github.com/jqlang/jq)

### Project structure
- `getoverhere.sh`: The script itself.
- `goh`: A symbolic link to make the things easier.
- `GetOverHererFile.json`: The default configuration file. This file is a template for the default configurations file. See [how to use](#how-to-use) for further informations. The file contents is showing bellow:
    ```
    {

        "defaultHeaders": [
            {
                "key":"Accept",
                "value":"*/*"
            },
            {
                "key":"Accept-Encoding",
                "value":"gzip, deflate, br"

            },
            {
                "key":"Connection",
                "value":"keep-alive"
            }

        ],
        "curlOptions":"--location --silent --show-error"
    }

    ```

    - `"defaultHeaders"`: It is the default headers for all requests. Which means that these headers will be sent for every request that are made.
    - `"curlOptions"`: Are the default options for curl command. All curl options that are put here will be part of the curl command for every request that are made.
- `dev.env`: This is just a sample file for an development environment (environment variables) configuration. See [how to use](#how-to-use) for further informations. The file contents is showing bellow:
    ```
    API_URL=http://localhost:8081
    ```
- `prd.env`: This is just a sample file for an production environment (environment variables) configuration. See [how to use](#how-to-use) for further informations. The file contents is showing bellow:
    ```
    API_URL=http://my-api.com
    ```

- `.env`: This is just a sample file for an environment (environment variables) configuration. See [how to use](#how-to-use) for further informations. The file contents is showing bellow:
    ```
    API_KEY=1234
    ```
- `README.md`: This very file.
- `request-config-template.json`: This is a template for the request config file. Each request must have its own config file.  See [how to use](#how-to-use) for further informations. The file contents is showing bellow:
    ```
    {
        "environment": "dev",
        "name":"Name of the API",
        "description":"Some optional description",
        "method":"GET",
        "uri":"${API_URL}/rest/important-api",
        "outputFormat": "json",
        "params": [
            {
                "key": "param1",
                "value": "value1"
            },
            {
                "key": "param2",
                "value": "value2"
            }
        ],
        "headers": [
            {
                "key":"Important-header",
                "value":"Important value"
            },
            {
                "key":"Another-Important-Header",
                "value":"Another important value"
            }
        ],
        "body": {
            "key1": "value1",
            "key2": "value2"
        }
    }
    ```
    - `"environment"`: The environment for the request. This is an optional property but if it is present
    the environment file must exists. See [how to use](#how-to-use) for further informations.
    - `"name"`: The name (high level identification) of the API
    - `"description"`: A short description of the API
    - `"method"`: The HTTP request method (GET, POST, PUT, PATCH or DELETE)
    - `"uri"`: End-point to the API
    - `"outputformat"`: Format which response will be presented. At this moment only "json" is supported
    - `"params"`: The key-value params for the query string when the method is "GET"
    - `"headers"`: The key-value headers that will be sended with the request.
    - `"body"`: It is a json body for the request. This property makes sense only for POST, PUT and PATCH
    request methods. At this moment only "raw json" body is supported. (But unlike output there is no
    "inputFormat" property)

### How to use
First of all you need to download the script and put it in some directory in your OS.
Now you need to give execution permission to the script and its synbolic linkk. To do that navigate
to the directory where you saved the script and run the follow commands:
```
sudo chmod +x getoverherer.sh && sudo chmod +x goh
```
After that add the directory where you save the script in the previous step in the PATH variable.
You can do that by putting the follow line in you "/etc/environment" file or "~/.bashrc" file or "~/.profile" file
according to you own needs.
```
export PATH=$PATH:<directory where you saved the script>
```
Now you have dowloaded the script and put its directory into PATH variable let's using it.
If you will use the default configurations you must create the "GetOverHererFile.json" in the same directory where
the script will be called from. The file's structure was described above.

If you use different environments like development, homologation, production and so on you can create as many
enviroment files as you need. This environment files must be created is the same directory where the script will be
called from just like "GetOverHererFile.json" and its extension must to be ".env".
When you referenciate an environment file you just use its name without ".env" extension. Let's imagine you create an
enviroment file called "dev.env". When you are going to use it (in the configuration file or in the script's options)
you just refers to it as "dev".

Besides that you can create a special ".env" file called just ".dev". This special ".env" file will be loaded every
requests that are made. Which means you can create environment variables in this file regardless the environment you will use.
That's include secret ones. If you will put yours request configuration files and environment ones in a csv repository
I strongly recomend tha you keep this ".env" file out of it.

Now you just need to create as many requests configuration files as you wish.
The configuration files can be created in any directory you wish because you need to put its path in "-i" option when
the script is called. Type getoverherer.sh (or goh if you have created the symbolic link) and hit enter key to see
the script's help.

### Example
Let's put an example to better understanding.
```
~/my-workspace
|
|__general_registrations
|  |__create_new_customer.json
|  |__list_customers.json
|
|__sales
|  |__create_new_sale.json
|
|__GetOverHererFile.json
|__dev.env
|__prd.env
|__.env
```
- `~/my-worspace`: The directory where the script will be called from
- `~/my-worspace/general_registrations`: Directory that contains request configuration files for "general_registrations" module.
- `~/my-worspace/general_registrations/create_new_customer.json`: The request configuration file for test the "create new customer" API
- `~/my-worspace/general_registrations/list_customers.json`: The request configuration file for test the "list customers" API
- `~/my-worspace/sales`: Directory that contains request configuration files for "sales" module
- `~/my-worspace/sales/create_new_sale.json`: The request configuration file for test "create new sale" API
- `~/my-worspace/GetOverHererFile.json`: The default configurations file that was described above.
- `~/my-worspace/dev.env`: The development environment configurations file that was described above.
- `~/my-worspace/prd.env`: The production environment configurations file that was described above.
- `~/my-worspace/.env`: The environment configurations file that was described above.

*P.S. The files contents does not are show here because has examples above*

When you want to test "create customer" API just type the follow line and hit enter:
```
[user@computer my-workspace]$ goh -i ./general_registrations/create_new_customer.json
```
Note that you are in the "my-workspace" directory and this execution will send the request using the "environment" that
you put in the "create_new_customer.json".

That is it.
