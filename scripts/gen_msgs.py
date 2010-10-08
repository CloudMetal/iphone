#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Example implementation.

If run, access token

"""
import string
import simplejson

from yammer.yammer import Yammer, YammerError

try:
    from local_settings import *
except ImportError:
    pass

"""
ORIGINAL AUTHOR:
__author__ = 'Jonas Nockert'
__license__ = "MIT"
__version__ = '0.2'
__email__ = "jonasnockert@gmail.com"

"""

def get_proxy_info():
    """ Ask user for proxy information if not already defined in
    configuration file.

    """
    # Set defaults
    proxy = {'host': None,
             'port': None,
             'username': None,
             'password': None}

    # Is proxy host set? If not, ask user for proxy information
    if 'proxy_host' not in globals():
        proxy_yesno = raw_input("Use http proxy? [y/N]: ")
        if string.strip((proxy_yesno.lower())[0:1]) == 'y':
            proxy['host'] = raw_input("Proxy hostname: ")
            port = raw_input("Proxy port: ")
            if not port:
                port = 8080
            proxy['port'] = int(port)
            proxy['username'] = raw_input("Proxy username (return for none): ")
            if len(proxy['username']) != 0:
                proxy['password'] = raw_input("Proxy password: ")
    else:
        proxy['host'] = proxy_host
        if 'proxy_port' in globals():
            proxy['port'] = proxy_port
        else:
            proxy['port'] = 8080
        if 'proxy_username' in globals():
            proxy['username'] = proxy_username
        if 'proxy_password' in globals():
            proxy['password'] = proxy_password

    return proxy

def get_consumer_info():
    """ Get consumer key and secret from user unless defined in
    local settings.

    """
    consumer = {'key': None,
                'secret': None}
    if ('consumer_key' not in globals()
            or not consumer_key
            or 'consumer_secret' not in globals()
            or not consumer_secret):
        print "\n#1 ... visit https://www.yammer.com/client_applications/new"
        print "       to register your application.\n"

        consumer['key'] = raw_input("Enter consumer key: ")
        consumer['secret'] = raw_input("Enter consumer secret: ")
    else:
        consumer['key'] = consumer_key
        consumer['secret'] = consumer_secret

    if not consumer['key'] or not consumer['secret']:
        print "*** Error: Consumer key or (%s) secret (%s) not valid.\n" % (
                                                        consumer['key'],
                                                        consumer['secret'])
        raise StandardError("Consumer key or secret not valid")

    return consumer

#
# Main
#

yammer = None
proxy = get_proxy_info()
consumer = get_consumer_info()

# If we already have an access token, we don't need to do the full
# OAuth dance
if ('access_token_key' not in globals()
            or not access_token_key
            or 'access_token_secret' not in globals()
            or not access_token_secret):
    try:
        yammer = Yammer(consumer['key'],
                        consumer['secret'],
                        proxy_host=proxy['host'],
                        proxy_port=proxy['port'],
                        proxy_username=proxy['username'],
                        proxy_password=proxy['password'])
    except YammerError, m:
        print "*** Error: %s" % m.message
        quit()

    print "\n#2 ... Fetching request token.\n"

    try:
        unauth_request_token = yammer.fetch_request_token()
    except YammerError, m:
        print "*** Error: %s" % m.message
        quit()

    unauth_request_token_key = unauth_request_token.key
    unauth_request_token_secret = unauth_request_token.secret

    try:
        url = yammer.get_authorization_url(unauth_request_token)
    except YammerError, m:
        print "*** Error: %s" % m.message
        quit()

    print "#3 ... Manually authorize via url: %s\n" % url
    import webbrowser
    webbrowser.open(url)

    oauth_verifier = raw_input("After authorizing, enter the OAuth "
                               "verifier (four characters): ")

    print "\n#4 ... Fetching access token.\n"

    try:
        access_token = yammer.fetch_access_token(unauth_request_token_key,
                                                 unauth_request_token_secret,
                                                 oauth_verifier)
    except YammerError, m:
        print "*** Error: %s" % m.message
        quit()

    access_token_key = access_token.key
    access_token_secret = access_token.secret

    print "Your access token:\n"
    print "Key:    %s" % access_token_key
    print "Secret: %s" % access_token_secret

    save_config = string.strip(
        raw_input("Write a config file to skip these steps next time? [y/N]").lower())[0:1] == 'y'
    if save_config:
      with open('local_settings.py', 'w') as f:
        f.write(
            "consumer_key='%s'\nconsumer_secret='%s'\naccess_token_key='%s'"
            "\naccess_token_secret='%s'\ndebug=False\nproxy_host='%s'\nproxy_port='%s'"
            "\nproxy_username='%s'\nproxy_password='%s'\nusername=''" % (
              consumer['key'], consumer['secret'], access_token_key, access_token_secret,
              proxy['host'], proxy['port'], proxy['username'], proxy['password']))

#if 'username' not in globals():
    #username = raw_input("Enter Yammer username (or return for "
                         #"current): ")


from oauth.oauth import (OAuthClient, OAuthConsumer, OAuthError,
                         OAuthRequest, OAuthSignatureMethod_HMAC_SHA1,
                         OAuthSignatureMethod_PLAINTEXT, OAuthToken)
import json, socket, time
from yammer import yammer


class AwesomeYammer(yammer.Yammer):
  def _fetch_resource(self, url, params=None, method=None, body=None):
    if not body and not method or method == 'GET':
      return Yammer._fetch_resource(self, url, params)
    
    if not self._access_token: raise YammerError('missing access token')
    try:
      o = OAuthRequest.from_consumer_and_token(
          self._consumer, token=self._access_token, http_method=method,
          http_url=url, parameters=params)
      headers = o.to_header()
      o.sign_request(self._signature, self._consumer, self._access_token)
      url = o.to_url()
    except OAuthError, m: raise YammerError(m.message)
    try:
      self._connection.request(o.http_method, url, body=body, headers=headers)
    except socket.gaierror, (n, m):
      raise YammerError(m)
    resp = self._connection.getresponse()
    status = resp.status
    if status not in (200, 201):
      raise YammerError('%s returned HTTP code %d' % (url, status))
    return resp.read()

  def create_message(self, msg_body):
    from urllib import quote_plus
    b = 'body=%s' % quote_plus(msg_body)
    url = '%smessages.json' % yammer.YAMMER_API_BASE_URL
    try:
      ret = json.loads(self._fetch_resource(url, method='POST', body=b))
    except ValueError: raise YammerError('Could not decode message response json')
    return ret
  


# If we just got our access key, we already have a Yammer instance

print ''
print 'Available commands:'
print ''
print 'gen-messages n:100 to:tomsg    - generates `n` number of messages directed `to` a group or user'
print 'exit                           - quits yammer prompt'
print ''
cmd = raw_input('yammer-api $ ')
while cmd.strip() != 'exit':
  if not len(cmd): exit()
  s = cmd.split(' ')
  for i, y in enumerate(s): s[i] = y.strip()

  if s[0] == 'gen-messages':
    num = 1
    to = None
    for arg in s[1:]:
      a, v = arg.split(':')
      if a == 'n': num = int(v)
      elif a == 'to': to = v
    Y = AwesomeYammer(consumer['key'], consumer['secret'], access_token_key, access_token_secret,
          proxy['host'], proxy['port'], proxy['username'], proxy['password'])
    m = 'this is a test message %d'
    for n in xrange(num):
      M = '%s%s' % ('' if not to else 'to:'+to+' ', (m % n))
      try:
        x = Y.create_message(M)
        print 'created', n, M
      except YammerError, e:
        print "Error", str(e)
      if num > 10:
        time.sleep(2.5)
  cmd = raw_input('yammer-api $ ')

  
