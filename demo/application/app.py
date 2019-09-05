from flask import Flask, request, render_template, abort

from datetime import datetime
import configparser
import json
import logging
import logging.config
import os
import requests
import socket
import db_client

dbc = None
vclient = None
hostname = socket.gethostname()
os.environ['no_proxy'] = '127.0.0.1,localhost'

log_level = {
  'CRITICAL' : 50,
  'ERROR'       : 40,
  'WARN'       : 30,
  'INFO'       : 20,
  'DEBUG'       : 10
}

logger = logging.getLogger('app')

app = Flask(__name__)
app.config['TEMPLATES_AUTO_RELOAD'] = True
app.debug = True

class DatacenterClass:
    def __init__(self,location):
        self.location = location
        self.url = None
        self.query = None
        self.service = None
        self.target = None
        self.color = None
        self.count = None
        self.urlResult = None
        self.jsonResult = None

datacenterlist = []

# Get datacenter info based on the location and store it in an array
def get_datacenter_info(location,target):
    logger.debug('Datacenter: {}'.format(location))
    try:
      x = DatacenterClass(location)
      x.query = json.loads(requests.get("http://127.0.0.1:8500/v1/query/{}/execute?dc={}".format(target, location)).content)
      x.service = x.query['Nodes'][0]['Service']
      x.target = "{}.query.consul".format(target)
      x.url = "http://" + x.service['Address'] + ":" + str(x.service['Port'])
      x.urlResult = requests.get(x.url).content
      logger.warn(x.urlResult)
      x.jsonResult = json.loads(x.urlResult)
      x.color = x.jsonResult['NOMAD_GROUP_NAME']
      x.count = len(x.query['Nodes'])
    except Exception:
      x = None
      logger.exception("Fatal error in datacenter query")
    datacenterlist.append(x)

def read_config():
  conf = configparser.ConfigParser()
  with open('./config/config.ini') as f:
    conf.read_file(f)
  return conf

@app.context_processor
def inject_dict_for_all_templates():
    return dict(hostname= hostname)

@app.route('/customers', methods=['GET'])
def get_customers():
    global dbc
    customers = dbc.get_customer_records()
    logger.debug('Customers: {}'.format(customers))
    return json.dumps(customers)

@app.route('/serviced', methods=['GET'])
def get_serviced():
    logger.warn('In serviced')
    #Clear out datacenter list
    datacenterlist.clear()
    #Get data from URL Query
    dclocations = json.loads(requests.get("http://127.0.0.1:8500/v1/catalog/datacenters").content)
    qtarget = request.args.get("filter")
    if qtarget == None:
        qtarget = 'profitapp'

    for l in dclocations:
        get_datacenter_info(l, qtarget)
    return render_template('serviced.html',datacenters=datacenterlist,conf=read_config())

@app.route('/serviceseg', methods=['GET'])
def get_serviceseg():

    defaultServiceURL = "http://profitapp-connect.service.consul:8080"
    connectEnabled = False

    serviceURL = request.args.get("serviceurl")


    if serviceURL == None:
        serviceURL = defaultServiceURL

    if "127.0.0.1" in serviceURL:
        connectEnabled = True

    #logger.warn(urlResult)
    return render_template('serviceseg.html',conf=read_config(),serviceurl=serviceURL,connectenabled=connectEnabled)

@app.route('/serviceexecute',methods=['GET'])
def get_serviceexecute():

    try:
        serviceURL = request.args.get("serviceurl")
        logger.warn(serviceURL)
        urlResult = requests.get(serviceURL).content
        urlResult = json.loads(urlResult)
    except Exception as e:
        if "127.0.0.1" in serviceURL:
            return "The Consul Connect Proxy is not working properly.  Exception: {}".format(e)
        else:
            return "Please check that the DNS service is working properly or the service name is valid"
    return json.dumps(urlResult)

@app.route('/customer', methods=['GET'])
def get_customer():
    global dbc
    cust_no = request.args.get('cust_no')
    if not cust_no:
      return '<html><body>Error: cust_no is a required argument for the customer endpoint.</body></html>', 500
    record = dbc.get_customer_record(cust_no)
    #logger.debug('Request: {}'.format(request))
    return json.dumps(record)

@app.route('/customers', methods=['POST'])
def create_customer():
    global dbc
    logging.debug("Form Data: {}".format(dict(request.form)))
    customer = {k:v for (k,v) in dict(request.form).items()}
    logging.debug('Customer: {}'.format(customer))
    if 'create_date' not in customer.keys():
      customer['create_date'] = datetime.now().isoformat()
    new_record = dbc.insert_customer_record(customer)
    logging.debug('New Record: {}'.format(new_record))
    return json.dumps(new_record)

@app.route('/customers', methods=['PUT'])
def update_customer():
    global dbc
    logging.debug('Form Data: {}'.format(dict(request.form)))
    customer = {k:v for (k,v) in dict(request.form).items()}
    logging.debug('Customer: {}'.format(customer))
    new_record = dbc.update_customer_record(customer)
    logging.debug('New Record: {}'.format(new_record))
    return json.dumps(new_record)

@app.route('/', methods=['GET'])
def index():
    return render_template('index.html', conf=dict(read_config()))

@app.route('/records', methods=['GET'])
def records():
    global dbc
    records = json.loads(get_customers())
    return render_template('records.html', results = records, dbusername = dbc.username, dbpassword = dbc.password, conf=read_config())

@app.route('/dbview', methods=['GET'])
def dbview():
    global dbc
    records = dbc.get_customer_records(raw = True)
    return render_template('dbview.html', results = records,conf=read_config())

@app.route('/dbuserview', methods=['GET'])
def dbuserview():
    global dbc
    records = dbc.get_users()
    return render_template('dbuserview.html', results = records, conf=read_config())

@app.route('/add', methods=['GET'])
def add():
    return render_template('add.html', conf=read_config())

@app.route('/add', methods=['POST'])
def add_submit():
    records = create_customer()
    return render_template('records.html', results = json.loads(records), record_added = True,conf=read_config())

@app.route('/update', methods=['GET'])
def update():
    return render_template('update.html', conf=read_config())

@app.route('/update', methods=['POST'])
def update_submit():
    records = update_customer()
    return render_template('records.html', results = json.loads(records), record_updated = True,conf=read_config())

if __name__ == '__main__':
  #logger.warn('In Main...')
  conf = read_config()

  logging.basicConfig(
    level=log_level[conf['DEFAULT']['LogLevel']],
    format='%(asctime)s - %(levelname)8s - %(name)9s - %(funcName)15s - %(message)s'
  )

  try:
    dbc = db_client.DbClient()

    if conf.has_section('VAULT'):
      if conf['VAULT']['Enabled'].lower() == 'true':
        if conf['VAULT']['Platform'].lower() == 'nomad':
          logger.info('Application running on Nomad')
          if 'VAULT_TOKEN' in os.environ:
            vault_token = os.environ['VAULT_TOKEN']
          else:
            vault_token = conf['VAULT']['Token']
          dbc.init_vault(addr=conf['VAULT']['Address'], token=vault_token, path=conf['VAULT']['KeyPath'], key_name=conf['VAULT']['KeyName'])
           
        if conf['VAULT']['Platform'].lower() == 'kubernetes':
          logger.info('Application running on Kubernetes')
          if 'VAULT_TOKEN' in os.environ:
            logger.info('VAULT_TOKEN already set')
            vault_token = os.environ['VAULT_TOKEN']
          else:
            dbc.init_vault_k8s(addr=conf['VAULT']['Address'], path=conf['VAULT']['KeyPath'], key_name=conf['VAULT']['KeyName'])

        if conf['VAULT']['DynamicDBCreds'].lower() == 'true':
          dbc.vault_db_auth(conf['VAULT']['DynamicDBCredsPath'])
          dbc.init_db(uri=conf['DATABASE']['Address'],
          prt=conf['DATABASE']['Port'],
          uname=dbc.username,
          pw=dbc.password,
          db=conf['DATABASE']['Database']
          )

      if dbc.is_initialized is False: # we didn't use dynamic credentials
        logger.info('Using DB credentials from config.ini...')
        dbc.init_db(
          uri=conf['DATABASE']['Address'],
          prt=conf['DATABASE']['Port'],
          uname=conf['DATABASE']['User'],
          pw=conf['DATABASE']['Password'],
          db=conf['DATABASE']['Database']
        )
    logger.info('Starting Flask server on {} listening on port {}'.format('0.0.0.0', '5000'))
    app.run(host='0.0.0.0', port=5000)

  except Exception as e:
    logging.error("There was an error starting the server: {}".format(e))
