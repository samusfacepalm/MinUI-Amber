#!/usr/bin/env python3
# /roms/MinUIAmber/.system/a10mini/bin/fixrefresh.py
#
# Set the A10 Mini panel to 60 Hz by changing only the pixel clock of the
# timing the kernel uses (display-timings/native-mode). The blanking
# (porches, sync widths) is left exactly as the vendor set it: on the v1
# panel, changing the blanking was what looked wrong, while a 4% faster
# clock with stock blanking was fine.
#
#   v1/v2  21.0 MHz, 735x495 total = 57.72 Hz -> 21.8295 MHz = 60.00 Hz
#   V4     30.0 MHz, 824x590 total = 61.71 Hz -> 29.1696 MHz = 60.00 Hz
#
# The clock is one 32-bit cell, so the DTB is patched in place with no
# size change and no dtc needed. Python 3.7 stdlib only (ArkOS4Clone).
#
#   fixrefresh.py check <dtb>   report, change nothing (exit 0)
#   fixrefresh.py apply <dtb>   patch if the panel is not already ~60 Hz

import struct
import sys

FDT_MAGIC = 0xd00dfeed
BEGIN_NODE, END_NODE, PROP, NOP, END = 1, 2, 3, 4, 9
TARGET_HZ = 60.0


def parse(blob):
	magic, totalsize, off_struct, off_strings = struct.unpack_from('>IIII', blob, 0)
	if magic != FDT_MAGIC:
		raise ValueError('not a device tree blob')
	size_strings, size_struct = struct.unpack_from('>II', blob, 32)

	def string(off):
		end = blob.index(b'\0', off_strings + off)
		return blob[off_strings + off:end].decode('ascii', 'replace')

	nodes = []   # (path, {prop: (abs_offset, length)})
	stack = []
	pos = off_struct
	limit = off_struct + size_struct
	while pos < limit:
		(tok,) = struct.unpack_from('>I', blob, pos)
		pos += 4
		if tok == BEGIN_NODE:
			end = blob.index(b'\0', pos)
			name = blob[pos:end].decode('ascii', 'replace')
			pos = (end + 1 + 3) & ~3
			path = (stack[-1][0] if stack else '') + '/' + name if name else '/'
			path = path.replace('//', '/')
			node = (path, {})
			stack.append(node)
			nodes.append(node)
		elif tok == END_NODE:
			stack.pop()
		elif tok == PROP:
			length, nameoff = struct.unpack_from('>II', blob, pos)
			pos += 8
			stack[-1][1][string(nameoff)] = (pos, length)
			pos = (pos + length + 3) & ~3
		elif tok == NOP:
			continue
		elif tok == END:
			break
		else:
			raise ValueError('bad token %d at %d' % (tok, pos - 4))
	return nodes


def u32(blob, prop):
	off, length = prop
	if length != 4:
		raise ValueError('expected a 32-bit cell')
	return struct.unpack_from('>I', blob, off)[0]


def native_timing(blob, nodes):
	for path, props in nodes:
		if not path.endswith('/display-timings') or 'native-mode' not in props:
			continue
		want = u32(blob, props['native-mode'])
		for cpath, cprops in nodes:
			if cpath.startswith(path + '/') and 'phandle' in cprops and u32(blob, cprops['phandle']) == want:
				return cpath, cprops
	raise ValueError('no display-timings native-mode found')


def describe(blob, props):
	g = lambda k: u32(blob, props[k])
	ht = g('hactive') + g('hfront-porch') + g('hsync-len') + g('hback-porch')
	vt = g('vactive') + g('vfront-porch') + g('vsync-len') + g('vback-porch')
	clk = g('clock-frequency')
	return g('hactive'), g('vactive'), ht, vt, clk, clk / float(ht * vt)


def main():
	if len(sys.argv) != 3 or sys.argv[1] not in ('check', 'apply'):
		print('usage: fixrefresh.py check|apply <dtb>')
		return 2
	mode, path = sys.argv[1], sys.argv[2]
	blob = bytearray(open(path, 'rb').read())
	nodes = parse(blob)
	tpath, props = native_timing(blob, nodes)
	w, h, ht, vt, clk, hz = describe(blob, props)
	print('panel %dx%d, timing %s: %d Hz clock, %dx%d total = %.2f Hz' % (w, h, tpath, clk, ht, vt, hz))

	if abs(hz - TARGET_HZ) < 0.1:
		print('already 60 Hz, nothing to do')
		return 0
	if not 50.0 < hz < 70.0:
		print('refresh outside 50-70 Hz; not a timing this script knows, leaving it alone')
		return 1
	new_clk = ht * vt * int(TARGET_HZ)
	if mode == 'check':
		print('would set clock to %d Hz (%.2f Hz)' % (new_clk, new_clk / float(ht * vt)))
		return 0

	struct.pack_into('>I', blob, props['clock-frequency'][0], new_clk)
	# re-parse what we are about to write before touching the file
	_, _, _, _, clk2, hz2 = describe(blob, native_timing(blob, parse(blob))[1])
	if clk2 != new_clk:
		print('verification failed, file not written')
		return 1
	with open(path, 'r+b') as f:
		f.write(blob)
		f.flush()
	print('set clock to %d Hz: %.2f Hz' % (clk2, hz2))
	return 0


if __name__ == '__main__':
	try:
		sys.exit(main())
	except (ValueError, struct.error, IndexError, KeyError, OSError) as e:
		print('cannot patch: %s' % e)
		sys.exit(1)
