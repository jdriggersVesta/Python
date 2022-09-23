# VIP Scoring Model

## Configuring Anaconda
* https://www.anaconda.com/
* https://docs.anaconda.com/anaconda/install/windows/

## Install Missing Libraries

## Adding Snowflake Credentials to Local Environment Variables
Add your Snowflake credentials to windows local environment variables
* https://docs.oracle.com/en/database/oracle/machine-learning/oml4r/1.5.1/oread/creating-and-modifying-environment-variables-on-windows.html#GUID-DD6F9982-60D5-48F6-8270-A27EC53807D0
```
    username = os.getenv('Snowflake_User')
    password = os.getenv('Snowflake_password')
    account = os.getenv('Snowflake_account')
```
