// Convert CC0 GLB vertex attributes from KHR_mesh_quantization to core glTF floats.
const fs = require('fs');
const path = require('path');
const directory = path.resolve(__dirname, '../assets/models');
for (const name of fs.readdirSync(directory).filter(n => n.endsWith('.glb'))) {
  const file = path.join(directory, name);
  const source = fs.readFileSync(file);
  const jsonLength = source.readUInt32LE(12);
  const doc = JSON.parse(source.subarray(20, 20 + jsonLength).toString());
  if (!doc.extensionsUsed?.includes('KHR_mesh_quantization')) continue;
  const binHeader = 20 + jsonLength;
  const original = source.subarray(binHeader + 8, binHeader + 8 + source.readUInt32LE(binHeader));
  const chunks = [original];
  let offset = original.length;
  const attributes = new Set();
  for (const mesh of doc.meshes) for (const primitive of mesh.primitives) {
    for (const [key, value] of Object.entries(primitive.attributes)) {
      if (!key.startsWith('JOINTS')) attributes.add(value);
    }
  }
  for (const index of attributes) {
    const a = doc.accessors[index];
    if (a.componentType === 5126) continue;
    const view = doc.bufferViews[a.bufferView];
    const formats = {5120: ['readInt8',1,127], 5121:['readUInt8',1,255],5122:['readInt16LE',2,32767],5123:['readUInt16LE',2,65535]};
    const [read, bytes, divisor] = formats[a.componentType];
    const components = {SCALAR:1,VEC2:2,VEC3:3,VEC4:4}[a.type];
    const stride = view.byteStride || bytes * components;
    const start = (view.byteOffset || 0) + (a.byteOffset || 0);
    const floatData = Buffer.alloc(a.count * components * 4);
    const convert = n => a.normalized ? Math.max(-1, n / divisor) : n;
    for (let row = 0; row < a.count; row++) for (let component = 0; component < components; component++) {
      floatData.writeFloatLE(convert(original[read](start + row * stride + component * bytes)), (row * components + component) * 4);
    }
    for (const bound of ['min','max']) if (a[bound]) a[bound] = a[bound].map(convert);
    a.bufferView = doc.bufferViews.length;
    doc.bufferViews.push({buffer:0,byteOffset:offset,byteLength:floatData.length,target:34962});
    a.componentType = 5126;
    a.byteOffset = 0;
    delete a.normalized;
    chunks.push(floatData);
    offset += floatData.length;
  }
  for (const key of ['extensionsUsed','extensionsRequired']) {
    doc[key] = (doc[key] || []).filter(e => e !== 'KHR_mesh_quantization');
    if (!doc[key].length) delete doc[key];
  }
  doc.buffers[0].byteLength = offset;
  const json = Buffer.from(JSON.stringify(doc));
  const paddedJson = Buffer.alloc(Math.ceil(json.length / 4) * 4, 32);
  json.copy(paddedJson);
  const bin = Buffer.concat(chunks);
  const header = Buffer.alloc(20);
  header.write('glTF'); header.writeUInt32LE(2,4);
  header.writeUInt32LE(28 + paddedJson.length + bin.length,8);
  header.writeUInt32LE(paddedJson.length,12); header.write('JSON',16);
  const binaryHeader = Buffer.alloc(8);
  binaryHeader.writeUInt32LE(bin.length,0); binaryHeader.write('BIN\0',4);
  fs.writeFileSync(file,Buffer.concat([header,paddedJson,binaryHeader,bin]));
  console.log('Converted',name);
}
