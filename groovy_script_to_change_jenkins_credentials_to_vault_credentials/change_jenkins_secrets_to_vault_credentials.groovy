import java.io.InputStream;
import java.io.FileInputStream
import java.io.File;
import javax.xml.transform.stream.StreamSource

//project name 
project = "groovy"

//value to be changed
org_string = "Hello world"

//new value
final_string = "hi wold"


// Required vault values
vault_url = 'http://13.126.44.161:8080'
vault_credential_id = 'jenkins'
secret_path = 'kv/secret'
env_variable = 'user'
key = 'foo'

//creation of porject instance
job = Jenkins.instance.getItem(project)

//Getting configuration file of the specified project
configXMLFile = job.getConfigFile();

//creating a backup of conf file
backup_file = new File("/var/lib/jenkins/${project}_conf_backup.txt")
backup_file.write(configXMLFile.asString())

//replacing values
updated_file = configXMLFile.asString().replace(org_string, final_string )

//creating a new file for the conf
inputFile = new File("/var/lib/jenkins/${project}_conf_dup.txt")
inputFile.write(updated_file)

// Disabling jenkins secrets plugin from the project
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



//Getting vault plugin name and plugin version
Jenkins.instance.pluginManager.plugins.each { plugin ->
  if ("${plugin.getShortName()}".contains('vault')) {
    println ("${plugin.getDisplayName()} (${plugin.getShortName()}): ${plugin.getVersion()}")
    vault_plugin_name = "${plugin.getShortName()}"
    vault_plugin_version = "${plugin.getVersion()}"
  }
}

//Enabling vault plugin
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

//Saving the change
InputStream is = new FileInputStream(inputFile)
job.updateByXml(new StreamSource(is))
job.save()

//printing final conf
println Jenkins.instance.getItem(project).getConfigFile().asString()