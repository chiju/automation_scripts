import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.Credentials
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.hudson.plugins.folder.Folder

Set<Credentials> credentials =
  CredentialsProvider.lookupCredentials(Credentials.class)

Jenkins.instance.getAllItems(Folder.class).each { folder ->
  credentials.addAll(
    CredentialsProvider.lookupCredentials(Credentials.class, folder)
  )
}

def creds = []

credentials.each { credential ->
  creds.add(credential.properties)
}

def string_to_remove = 'secretBytes='

for (item in creds) {
  for (it in item) {
    if (it.toString().contains('password=')) {
      password = it.toString()
    }
    if (it.toString().contains('username')) {
      println "======="
      println it.toString()
      println password
      println "=======\n"
    }
    if (it.toString().contains('id=')) {
      id = it.toString()
      println id
    }
    if ( it.toString().contains('secretBytes=') ) {      
      string_to_remove = 'secretBytes='
      def secret_file = it.toString() - string_to_remove
      println "======="
      println(new String(com.cloudbees.plugins.credentials.SecretBytes.fromString(secret_file).getPlainData(), "ASCII"))
      println "=======\n"
    }
    if ( it.toString().contains('secret=')) {
      println "======="
      println it.toString()
      println "=======\n"
    }
  }
}