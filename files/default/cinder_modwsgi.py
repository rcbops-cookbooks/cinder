from paste import deploy

from oslo.config import cfg

from cinder.common import config
from cinder.openstack.common import gettextutils
from cinder.openstack.common import log as logging
from cinder import rpc
from cinder import version

gettextutils.enable_lazy()

CONF=cfg.CONF
CONF("", project='cinder', version=version.version_string())

logging.setup("cinder")

rpc.init(CONF)

conf = '/etc/cinder/api-paste.ini'
name = "osapi_volume"

application = deploy.loadapp('config:%s' % conf, name=name)
