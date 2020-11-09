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

