
# Import python libs
import logging
import yaml
import re
import fnmatch

from salt.utils.odict import OrderedDict
from Crypto.Cipher import AES
import base64


# the block size for the cipher object; must be 16, 24, or 32 for AES
BLOCK_SIZE = 32

# the character used for padding--with a block cipher such as AES, the value
# you encrypt must be a multiple of BLOCK_SIZE in length.  This character is
# used to ensure that your value is always a multiple of BLOCK_SIZE
PADDING = '{'

# one-liner to sufficiently pad the text to be encrypted
pad = lambda s: s + (BLOCK_SIZE - len(s) % BLOCK_SIZE) * PADDING

# one-liners to encrypt/encode and decrypt/decode a string
# encrypt with AES, encode with base64
EncodeAES = lambda c, s: base64.b64encode(c.encrypt(pad(s)))
DecodeAES = lambda c, e: c.decrypt(base64.b64decode(e)).rstrip(PADDING)

log = logging.getLogger(__name__)


def __virtual__():
    return 'demo_enc_pillar'

def _read_from_config(config_file):
    '''
    read sls file
    '''
    log.info("CLIENT: Reading config file (%s)..." % (config_file))
    with open('%s' % config_file, 'r') as orig_config:
         config_dict = yaml.load(orig_config) or {}
         return config_dict

def get_encrypted_pillar_list(salt_key):
    '''
    return list of encrypted pillar  for a targeted minion
    '''
    #getting pillar_home
    pillar_home=__opts__['file_roots']['base'][0]

    dict_top={}
    with open("%s/top.sls" % pillar_home, 'r') as orig_config:
         dict_top = yaml.load(orig_config) or {}

    secret_pillar=[]

    for match in dict_top['base']:
        if fnmatch.fnmatch(salt_key, match):
            print "Match : "
            print dict_top['base'][match]
            for pillar_id in dict_top['base'][match]:
                if 'enc' in pillar_id:
                    secret_pillar.append(pillar_id)
    return secret_pillar

def get_enc_pillar_file_name(pillar_id):
    '''
    return the complete file name from the pillar id
    '''
    #getting pillar_home
    pillar_home=__opts__['file_roots']['base'][0]
    return pillar_home + "/" + pillar_id.replace(".", "/") + ".sls"

def get_real_pillar(value, args):
    '''
    decrypt  pillar value
    '''
    cipher = AES.new(args)
    return DecodeAES(cipher, value)

def get_value_from_enc_pillar(pillar_id, args):
    '''
    return dict after decrypting values for a encrypted pillar file
    '''
    sec_pillar_dict={}
    config_file=get_enc_pillar_file_name(pillar_id)
    print "reading file : %s" % config_file
    with open('%s' % config_file, 'r') as orig_config:
        config = yaml.load(orig_config) or {}
        print config
        for key in config:
            log.info("Reading %s key "  % key)
            subkey_dict=config[key]
            print subkey_dict
            sec_pillar_sub_dict={}
            for subkey in subkey_dict:
                log.info("Reading %s sub key "  % subkey)
                sec_pillar_sub_dict[subkey]=get_real_pillar(subkey_dict[subkey], args)
            sec_pillar_dict[key]=sec_pillar_sub_dict
    return sec_pillar_dict

def ext_pillar(pillar, args):
    '''
    entry method for external pillar module
    pillar
        dictionary of existing compiled pillar values
    args
        arguments specified in salt master configuration
    '''

    my_pillar = {}
    #getting list of encrypted pillars configured in top file for current minion id
    secrets_list = get_encrypted_pillar_list(__grains__['id'])

    #updating custome pillar dict with the values from configured encrypted pillar files
    for secrets_id in secrets_list:
        my_pillar.update(get_value_from_enc_pillar(secrets_id, args))

    return my_pillar
