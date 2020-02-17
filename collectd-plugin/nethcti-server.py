import json
import collectd
import requests
import MySQLdb
import datetime

CONFIG = {
    'Host': '127.0.0.1',
    'Debug': 'False',
    'DB_Host': '127.0.0.1',
    'DB_User': '',
    'DB_Password': '',
    'DB_Name': 'asteriskcdrdb'
}
REST_PROF = 'http://127.0.0.1/webrest/profiling/all'
PLUGIN_NAME = 'nethcti-server'
QUERY=""

def clog(msg):
    if CONFIG['Debug'] == 'True':
        collectd.info('plugin_nethcti-server: %s' % msg)

def config_cb(conf):
    for node in conf.children:
        CONFIG[node.key] = node.values[0]

def init_cb():
    global QUERY
    clog('init')
    now = datetime.datetime.now()
    delta = datetime.timedelta(minutes=1)
    earlier = (now - delta).strftime("%Y-%m-%d %H:%M:00")
    QUERY="SELECT count(*) FROM cdr WHERE calldate >= \"" + earlier + "\" AND calldate < \"" + now.strftime("%Y-%m-%d %H:%M:00") + "\""

def read_cb():
    clog('GET ' + REST_PROF)
    r = requests.get(REST_PROF)
    info = json.loads(r.text)
    if r.status_code == 200:
        # users
        tot_users = info['tot_users']
        ws_conn_clients = info['conn_clients']['ws_conn_clients']
        tcp_conn_clients = info['conn_clients']['tcp_conn_clients']['tot']
        dispatch_value('Tot Users', 'Tot Users', tot_users, 'gauge')
        dispatch_value('Conn Users', 'WS Conn Users', ws_conn_clients, 'gauge')
        dispatch_value('Conn Users', 'TCP Conn Users', tcp_conn_clients, 'gauge')
        # mem
        rss = info['proc_mem']['rss']
        heapTotal = info['proc_mem']['heapTotal']
        heapUsed = info['proc_mem']['heapUsed']
        external = info['proc_mem']['external']
        dispatch_value('Memory usage', 'Rss', rss, 'memory')
        dispatch_value('Memory usage', 'Heap Total', heapTotal, 'memory')
        dispatch_value('Memory usage', 'Heap Used', heapUsed, 'memory')
        dispatch_value('Memory usage', 'External', external, 'memory')
    else:
        clog('error GET ' + REST_PROF + ': status code ' + str(r.status_code))
    # number of calls
    try:
        clog(CONFIG['Host'])
        db = MySQLdb.connect(host=CONFIG['DB_Host'], user=CONFIG['DB_User'], passwd=CONFIG['DB_Password'], db=CONFIG['DB_Name'])
        cur = db.cursor()
        cur.execute(QUERY)
        count=cur.fetchone()[0]
        dispatch_value('Num Calls', 'Num Calls', count, 'gauge')
        db.close()
    except Exception as err:
        clog('error mysql ' + QUERY)
        clog(err)

def dispatch_value(plugin_instance, type_instance, value, type):
    clog("sending value: %s / %s = %s" % (plugin_instance, type_instance, value))
    vl = collectd.Values()
    vl.plugin = PLUGIN_NAME
    vl.plugin_instance = plugin_instance
    vl.type = type
    vl.type_instance = type_instance
    vl.values = [value]
    vl.dispatch()
    
collectd.register_config(config_cb)
collectd.register_init(init_cb)
collectd.register_read(read_cb)