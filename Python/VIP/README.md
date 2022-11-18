# VIP Scoring Model

## Configuring Anaconda
* https://www.anaconda.com/
* https://docs.anaconda.com/anaconda/install/windows/

## Install Missing Libraries
I had to manually install snowflake connector and imblearn libraries by creating a new env in Anaconda gui.

## Adding Snowflake Credentials to Local Environment Variables
Add your Snowflake credentials to windows local environment variables
* https://docs.oracle.com/en/database/oracle/machine-learning/oml4r/1.5.1/oread/creating-and-modifying-environment-variables-on-windows.html#GUID-DD6F9982-60D5-48F6-8270-A27EC53807D0
```
    username = os.getenv('Snowflake_User')
    password = os.getenv('Snowflake_password')
    account = os.getenv('Snowflake_account')
```
## Getting Started
Watch the video on the VIP process created by Matt W.
https://drive.google.com/file/d/1y2iCuRIZS35V4fDLeuLzWE7PK5i1FYq8/view?usp=sharing

Start executing the first code block, importing libraries
Continue executing each code block as instructed in the walkthrough video. You will then restart the kernal and clear all outputs so you can run the final model.