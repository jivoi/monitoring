#!/usr/bin/env python

import sys, getopt;
from sys import exit;
error = {'OK': 0,'WARNING': 1,'CRITICAL': 2,'UNKNOWN': 3,'DEPENDENT': 4};
key_host = [ ];
key_comm = [ ];
#
# Initialize help messages
options = 'Options:\n';
options = options + '  -H    name of host to request.\n';
options = options + '  -C    community of host.\n';
usage = 'Usage: %s [options] ' % sys.argv[0];
#
if len(sys.argv) != 3:
	try:
		(opts, args) = getopt.getopt(sys.argv[1:], 'H:C:', ['--host', '--community']);
	except getopt.error, why:
		print 'getopt error: %s\n%s' % (why, usage)
		sys.exit(error['UNKNOWN']);
#
	try:
		for opt in opts:
			if opt[0] == '-H' or opt[0] == '--host':
				key_host = opt[1];
			if opt[0] == '-C' or opt[0] == '--community':
				key_comm = opt[1];
	except ValueError, why:
		print 'Bad parameter \'%s\' for option %s: %s\n%s' \
          % (opt[1], opt[0], why, usage);
		sys.exit(error['UNKNOWN']);
else:
	try:
		key_host = sys.argv[1];
		key_comm = sys.argv[2];
	except:
		print 'getopt error: %s\n%s' % (why, usage)
		sys.exit(error['UNKNOWN']);
#
"""Command Generator Application (GET)"""
from pysnmp.mapping.udp.role import Manager;
from pysnmp.proto.api import alpha;

# Protocol version to use
ver = alpha.protoVersions[alpha.protoVersionId1];

# Build message
req = ver.Message();
req.apiAlphaSetCommunity(key_comm);

# Build PDU
req.apiAlphaSetPdu(ver.GetRequestPdu());
req.apiAlphaGetPdu().apiAlphaSetVarBindList(('1.3.6.1.2.1.1.1.0', ver.Null()),
                                           ('1.3.6.1.2.1.1.3.0', ver.Null()));

snmp_out = [ ];
def cbFun(wholeMsg, transportAddr, req):
	rsp = ver.Message();
	rsp.berDecode(wholeMsg);
	# Make sure this is a response to this request
	if req.apiAlphaMatch(rsp):
		global snmp_out;
		errorStatus = rsp.apiAlphaGetPdu().apiAlphaGetErrorStatus();
		if errorStatus:
			print 'Error: ', errorStatus;
			print 'Ooops...';
			sys.exit(error['UNKNOWN']);
		else:
			for varBind in rsp.apiAlphaGetPdu().apiAlphaGetVarBindList():
				snmp_out.append(varBind.apiAlphaGetOidVal());
	return 1;
try:
	tsp = Manager();
	tsp.sendAndReceive(req.berEncode(), (key_host, 161), (cbFun, req));
except:
	print 'Ooops...';
	sys.exit(error['UNKNOWN']);
#
seconds = snmp_out[1][1].get();
days = divmod(seconds, 8640000);
hours = divmod(seconds, 360000);
minutes = divmod(seconds, 6000);
tmp_hours = hours[0] - days[0] * 24;
print snmp_out[0][1].get(), 'Uptime: ', days[0], 'days', tmp_hours, 'hours', \
				minutes[0] - days[0] * 24 *60 - tmp_hours * 60, 'minutes';
exit(error['OK']);