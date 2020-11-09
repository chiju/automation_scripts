## Git commit for dns update

## Usage
Set environment variables for cloudflare_email_id and cloudflare_token
For Eg: 
```shell
export cloudflare_email_id="xyz@uvw.com"
export cloudflare_token="hlkfsdldkflls7d7ds7shhlkhlh4"
```
## Script 
### cloudflare tokens
```python
cloudflare_email_id = os.environ['cloudflare_email_id']
cloudflare_token = os.environ['cloudflare_token']
```
### ttl value
```
ttl = 120
```
### Getting the changes from git
```python
git_path = "/home/chiju/add-dns-entries"
repo = git.Repo(git_path)
path_to_a_file = "/home/chiju/add-dns-entries/records_new"
commits_touching_path = list(repo.iter_commits(paths=path_to_a_file))
changes = repo.git.diff(commits_touching_path[0], commits_touching_path[1], path_to_a_file)
```
### Record types
```python
type_records = ['SOA','A','TXT','NS','CNAME','MX','NAPTR','PTR','SRV','SPF','AAAA','CAA']
```
### Creating lists for adding and removing entries
```python
pattern = '^([-+]){1}([^-|+|\s])(.*)'
remove_list = []
add_list = []
for line in StringIO(changes):
   if re.match(pattern, line) and line.startswith('+'):
       stripped_line_r = line.lstrip('+').rstrip('\n').split(',')
       remove_list.append(stripped_line_r)
   if re.match(pattern, line) and line.startswith('-'):
       stripped_line_a = line.lstrip('-').rstrip('\n').split(',')
       add_list.append(stripped_line_a)
print("remove list\n", remove_list)
print("add list\n", add_list)
```
### Function for getting domain name from the "name" section of the record
```python
def split(strng, sep, pos):
  strng = strng.split(sep)
  return sep.join(strng[pos:])
```
### If the dns_provider is Cloudflare
```python
def cloudflare_dns():
  cf = CloudFlare.CloudFlare( email = cloudflare_email_id, token=cloudflare_token)  
  if record_type == 'MX':
    dns_record = { 'name':name, 'type':record_type, 'content':value, 'ttl':ttl, 'priority':int(rw[3])}
  else:
    dns_record = { 'name':name, 'type':record_type, 'content':value, 'ttl':ttl }
  zone_id = cf.zones.get(params={'name': domain})[0]['id']
  if rw in remove_list:
    try:
      record_id = cf.zones.dns_records.get(zone_id, params={'type': record_type, 'name': name, 'content':value})[0]['id']
      cf.zones.dns_records.delete(zone_id, record_id)
      print("Removed")
    except IndexError:
      print("Record is not present for deleting")
      pass
  else:
    try:
      cf.zones.dns_records.post(zone_id, data=dns_record)
      print("Added")
    except CloudFlare.exceptions.CloudFlareAPIError as e:
      print("Record already exists")
      pass
```
### If the dns provider is aws route53
```python
def route53_dns():
  
  value = rw[2]
  client = boto3.client('route53')

  # To get zone_id of of the hosted zone
  zone_id = client.list_hosted_zones_by_name( DNSName = domain, MaxItems='1')['HostedZones'][0]['Id'].split('/')[2]
  
  # Adding double quotes '"' in the value if the record type is TXT
  if record_type.upper() == 'TXT':
    value = '"' + value + '"'

  # Adding priority in the value section if the record type is MX
  if record_type.upper() == 'MX':
    priority = rw[3]
    value = priority + ' ' + value
  
  # For deleting dns records
  if rw in remove_list:
      
    # For handling error while trying to delete record values which are not present  
    try:
      current_values = client.list_resource_record_sets(
                              HostedZoneId = zone_id,
                              StartRecordName = name,
                              StartRecordType = record_type,
                              MaxItems = '1')['ResourceRecordSets'][0]['ResourceRecords']
      record_values = []
      for i in current_values:
        record_values.append(i['Value'])
      #print(current_values,"\n" ,record_values, "\n", value)
          
      # If there is only one value for the name (1)
      if len(record_values) == 1 and value in record_values:
        client.change_resource_record_sets(
                                        HostedZoneId = zone_id,
                                        ChangeBatch={
                                          'Changes': [{ 
                                            'Action': 'DELETE',
                                            'ResourceRecordSet': {
                                              'Name': name,
                                              'Type': record_type, 
                                              'TTL': ttl, 
                                              'ResourceRecords': [{
                                                'Value': value}]} }]})
        print("Removed")
         
      # If there is more than one value for a name
      else:
        if value in record_values:
          current_values.remove({'Value':value})
          client.change_resource_record_sets(
                                    HostedZoneId = zone_id,
                                    ChangeBatch={
                                        'Changes': [{ 
                                            'Action': 'UPSERT',
                                            'ResourceRecordSet': {
                                                'Name': name,
                                                'Type': record_type, 
                                                'TTL': ttl, 
                                                'ResourceRecords': current_values }}]})
          print("Removed")
        else:
          print("Record is not present for deleting")
        
    # Exception handling for (1)
    except ( IndexError, client.exceptions.InvalidChangeBatch ) as e:
      print("Record is not present for deleting")
      pass  
  
  # For adding records          
  if rw in add_list:
    try:
      client.change_resource_record_sets(
                                        HostedZoneId = zone_id,
                                        ChangeBatch={
                                          'Changes': [{ 
                                            'Action': 'CREATE',
                                            'ResourceRecordSet': {
                                              'Name': name,
                                              'Type': record_type, 
                                              'TTL': ttl, 
                                              'ResourceRecords': [{
                                                'Value': value}]} }]})
      print("Added\n")
  
    # Exception handling for InvalidChangeBatch and InvalidInput Errors
    except ( client.exceptions.InvalidChangeBatch, client.exceptions.InvalidInput ) as e:
    
      # If there is already DNS record with the same name and if we want to add value to the values section
      try:
        
        # To get current values of the DNS record
        current_values = client.list_resource_record_sets(
                              HostedZoneId = zone_id,
                              StartRecordName = name,
                              StartRecordType = record_type,
                              MaxItems = '1')['ResourceRecordSets'][0]['ResourceRecords']
        record_values = []
        for i in current_values:
          record_values.append(i['Value'])
      
        # To add the value to the values if the value is not present in the values
        if value not in record_values:
          current_values.append({'Value':value})
          client.change_resource_record_sets(
                                    HostedZoneId = zone_id,
                                    ChangeBatch={
                                      'Changes': [{ 
                                            'Action': 'UPSERT',
                                            'ResourceRecordSet': {
                                                'Name': name,
                                                'Type': record_type, 
                                                'TTL': ttl, 
                                                'ResourceRecords': current_values }}]})
          print("Added\n")
        else:
          print("Record already exists")                                                                        

      # handling InvalidInput error
      except client.exceptions.InvalidInput as e:
        print(e)
        print("PASSING\n")
        pass
```

### Looping through the records
```python
complete_list = remove_list + add_list

for rw in complete_list:
  if rw is None:
    continue
  if rw[1] not in type_records:
    print("\nNot a proper record, skipping... ", rw)
    continue  
  name = rw[0]
  record_type = rw[1]
  value = rw[2]
  domain = split(name, '.', -2) + '.'
  print("\n", domain)
  nameservers = []
  if record_type == 'ANAME':
      print("ANAME record, skipping..")
      continue
  try:
    answers = dns.resolver.query(domain, 'NS')
  except dns.exception.DNSException as e:
    print("domain name does not exist: ", domain)
    continue
      
  for rdata in answers:
    nameservers.append(rdata.to_text())
  if 'cloudflare' in nameservers[0].lower():
    print("cloudflare\n", rw)
    cloudflare_dns()
  if 'awsdns' in nameservers[0].lower():
    print("route53\n", rw)
    route53_dns()
```

## References
[Adding, deleting and updating dns records in route53](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/route53.html#Route53.Client.change_resource_record_sets)
[List dns records](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/route53.html#Route53.Client.list_resource_record_sets)
[Cloudflare API](https://github.com/cloudflare/python-cloudflare)