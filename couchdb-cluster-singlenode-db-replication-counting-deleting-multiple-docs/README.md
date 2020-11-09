# Couchdb - database replication between couchdb cluster and single node couchdb, count docs and delete docs

## Couchdb cluster creation

For  creating 3 node couch cluster, ansible playbook is there
[couch cluster creation playbook ](https://gitlab.com/devopsnexus/ansible/blob/apache-couchdb/couchdb.yml)

## Couchdb single node cluster
For creating single node couchdb
**single-node-couch.yaml** in the same folder as this README.md


## Creating database in cluster
Execute below curl command in any of the cluster nodes
```shell
create-database() { curl -X PUT http://admin:password@$(curl -s ifconfig.co):5984/$1; }; create-database database_name
```
where **database_name** is the prefered name of database 

## Replicating database from cluster couchdb to single node couch
Execute below command from any of the cluster node
```shell
curl -X PUT http://admin:password@$(curl -s ifconfig.co):5984/_replicator/my_rep -d '{ "_id": "my_rep", "source": "http://admin:password@localhost:5984/company_details", "target":  "http://admin:password@13.127.88.64:5984/company_details", "create_target":  true }'
```
where 
	**source** is source database
	**target** is target database (single node couch)
To see the status of replication
```shell
curl -s http://admin:password@$(curl -s ifconfig.co):5984/_scheduler/docs/_replicator/my_rep | jq
```

## Queries for counting and deleting docs
```python
import json
import requests
import sys

database = 'company_details'
server_ip = '13.127.88.64'
admin_user = 'admin'
password = 'password'

# Getting the count of jobs
url_org = "http://" + admin_user + ":" + password + '@' + server_ip + ':5984/{}'
requests.post(url_org.format(database), json = { "_id": "_design/count1",  "language": "javascript", "views": { "job": { "map": "function(doc) { if(doc[\"job\"] == \"job1\") emit(null, 1);}" , "reduce": "function(keys, values, combine) { return sum(values); }" } } } )
url = url_org	+ "/_design/count1/_view/job"
r = requests.get(url.format(database))
try:
  print(json.loads(r.text)['rows'][0]['value'])
except IndexError:
  pass

# Deleting the view
url	= url_org + "/_design/count1"
r = requests.get(url.format(database))
rev_id = json.loads(r.text)['_rev']
url = url_org + "/_design/count1?rev="
requests.delete(url.format(database) + rev_id)


# Deleting the required jobs
requests.post(url_org.format(database), json = { "_id": "_design/count2",  "language": "javascript", "views": { "job": { "map": "function(doc) { if(doc[\"job\"] == \"job2\") emit(doc._id, doc);}"} } } )
url = url_org + "/_design/count2/_view/job"
r_delete=requests.get(url.format(database))
rows=json.loads(r_delete.text)['rows']
todelete = []
for doc in rows:
  todelete.append({"_deleted": True, "_id": doc["value"]["_id"], "_rev": doc["value"]["_rev"]})
url = url_org + "/_bulk_docs"
r=requests.post(url.format(database), json={"docs": todelete})
print(r.status_code)

# Deleting the view
url = url_org + "/_design/count2"
r = requests.get(url.format(database))
rev_id = json.loads(r.text)['_rev']
url = url_org + "/_design/count2?rev="
req = requests.delete(url.format(database) + rev_id)
```
This script will count the number of docs which has "job" equals to "job1" and delete all the docs which has "job" equals to "job2" 
## Reference

[bulk update API doc](https://docs.couchdb.org/en/stable/api/database/bulk-api.html)

[map functions](https://docs.couchdb.org/en/stable/ddocs/ddocs.html?highlight=count#_count)