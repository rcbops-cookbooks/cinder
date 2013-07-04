import sys
from cinder.openstack.common import log as logging
from paste import deploy
from cinder import flags

flags.parse_args(sys.argv)
logging.setup("cinder")

conf = '/etc/cinder/api-paste.ini'
name = "osapi_volume"

application = deploy.loadapp('config:%s' % conf, name=name)
