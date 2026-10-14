const {test}=require('node:test');
const assert=require('node:assert/strict');
const http=require('node:http');
const {serve}=require('./serve-local-web.cjs');
test('same-origin API transport, static app, fail-closed boundaries and backend failure',async()=>{
 const upstream=http.createServer((req,res)=>{res.setHeader('Content-Type','application/json');res.end(JSON.stringify({path:req.url,method:req.method}));});
 await new Promise(r=>upstream.listen(0,'127.0.0.1',r));
 const server=await serve({port:0,backend:`http://127.0.0.1:${upstream.address().port}`});
 const origin=`http://127.0.0.1:${server.address().port}`;
 try {
  const response=await fetch(origin+'/api/v1/auth/login',{method:'POST',headers:{Origin:origin,'Content-Type':'application/json'},body:'{}'});
  assert.equal(response.status,200);assert.deepEqual(await response.json(),{path:'/api/v1/auth/login',method:'POST'});
  assert.match((await fetch(origin)).headers.get('content-type'),/text\/html/);
  assert.equal((await fetch(origin+'/api/v1/auth/login',{headers:{Origin:'https://attacker.invalid'}})).status,403);
  const hostile=await new Promise((resolve,reject)=>{const req=http.get(origin,{headers:{Host:'attacker.invalid'}},res=>{res.resume();resolve(res.statusCode);});req.on('error',reject);});assert.equal(hostile,403);
  assert.equal((await fetch(origin,{headers:{'X-Forwarded-Host':'attacker.invalid'}})).status,403);
  await new Promise(r=>upstream.close(r));
  assert.equal((await fetch(origin+'/api/v1/auth/login')).status,503);
  await assert.rejects(serve({port:0,backend:'https://example.invalid'}));
 }finally{upstream.closeAllConnections();upstream.close();server.closeAllConnections();await new Promise(r=>server.close(r));}
});
