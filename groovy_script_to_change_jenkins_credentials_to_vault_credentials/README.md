## Groovy script for changing buildwrapper from jenkins creds to vault creds

## Usage

- Add project name to **project** variable
- Add values to change in variables **org_string** and **final_string**
- Add vault app role credential

- vault details
```groovy
vault_url = 'http://13.126.44.161:8080'
vault_credential_id = 'jenkins'
secret_path = 'kv/secret'
env_variable = 'user'
key = 'foo'
```
where **vault_url** is the URL of vault server
      **vault_credential_id** is the role id in vault
      **secret_path** is the secret path
      **env_variable** is the name of the variable to be used
      **key** is the secret key name

## project name 
```groovy
project = "groovy"
```

## value to be changed
```groovy
org_string = "Hello world"
```
## new value
```groovy
final_string = "hi wold"
```

## Required vault values
```groovy
vault_url = 'http://13.126.44.161:8080'
vault_credential_id = 'jenkins'
secret_path = 'kv/secret'
env_variable = 'user'
key = 'foo'
```
## creation of porject instance
```groovy
job = Jenkins.instance.getItem(project)
```
## Getting configuration file of the specified project
```groovy
configXMLFile = job.getConfigFile();
```
## creating a backup of conf file
```groovy
backup_file = new File("/var/lib/jenkins/${project}_conf_backup.txt")
backup_file.write(configXMLFile.asString())
```
## replacing values
```groovy
updated_file = configXMLFile.asString().replace(org_string, final_string )
```
## creating a new file for the conf
```groovy
inputFile = new File("/var/lib/jenkins/${project}_conf_dup.txt")
inputFile.write(updated_file)
```
## Disabling jenkins secrets plugin from the project
```groovy
text = '' 
val = 0
vault_exists = 0
inputFile.eachLine { line ->
  if (line.contains('<com.datapipe.jenkins.vault.VaultBuildWrapper')) {
    vault_exists = 1
  }
  if (line.contains('<org.jenkinsci.plugins.credentialsbinding.impl.SecretBuildWrapper')) {
    val = 1
  }
  if (line.contains('</org.jenkinsci.plugins.credentialsbinding.impl.SecretBuildWrapper')) {
    val = 0
  }
  if (val == 0 && !line.contains('</org.jenkinsci.plugins.credentialsbinding.impl.SecretBuildWrapper')){
    text += line + "\n"
  }
}       
inputFile.write(text)
```

## Getting vault plugin name and plugin version
```groovy
Jenkins.instance.pluginManager.plugins.each { plugin ->
  if ("${plugin.getShortName()}".contains('vault')) {
    println ("${plugin.getDisplayName()} (${plugin.getShortName()}): ${plugin.getVersion()}")
    vault_plugin_name = "${plugin.getShortName()}"
    vault_plugin_version = "${plugin.getVersion()}"
  }
}
```
## Enabling vault plugin
```groovy
if (vault_exists == 0) {
  vault = '''<com.datapipe.jenkins.vault.VaultBuildWrapper plugin="''' + vault_plugin_name + '@' + vault_plugin_version +  '">' +
   '''<configuration>
        <vaultUrl>''' + vault_url + '''</vaultUrl>
        <vaultCredentialId>''' + vault_credential_id + '''</vaultCredentialId>
        <failIfNotFound>true</failIfNotFound>
        <skipSslVerification>false</skipSslVerification>
      </configuration>
      <vaultSecrets>
        <com.datapipe.jenkins.vault.model.VaultSecret>
          <path>''' + secret_path + '''</path>
          <secretValues>
            <com.datapipe.jenkins.vault.model.VaultSecretValue>
              <envVar>''' + env_variable + '''</envVar>
              <vaultKey>''' + key + '''</vaultKey>
            </com.datapipe.jenkins.vault.model.VaultSecretValue>
          </secretValues>
        </com.datapipe.jenkins.vault.model.VaultSecret>
      </vaultSecrets>
      <valuesToMask/>
      <vaultAccessor/>
    </com.datapipe.jenkins.vault.VaultBuildWrapper>
'''
text_new = ''
inputFile.eachLine { line ->
  if (line.contains('<buildWrappers>')) {
     text_new += line + "\n" + vault
  }
  else {
    text_new += line + "\n"
  }
}
inputFile.write(text_new)

}
```
## Saving the change
```groovy
InputStream is = new FileInputStream(inputFile)
job.updateByXml(new StreamSource(is))
job.save()
```
## printing final conf
```groovy
println Jenkins.instance.getItem(project).getConfigFile().asString()
}
```

## References

[Jenkins Documentation](https://javadoc.jenkins-ci.org/hudson/model/FreeStyleProject.html)


