const assert = require('node:assert/strict');
const fs = require('node:fs');
const src = fs.readFileSync('luci-app-auth-thu/htdocs/luci-static/resources/view/goauthing/setting.js', 'utf8');

function fixture({field, code = 0, apiAvailable = true, reject = false} = {}) {
  const calls = [], alerts = [], options = {};
  const textarea = {value: field, dispatchEvent(){}};
  const form = {Map: class {
    section() {return {option(type, name) {
      return options[name] = {formvalue: () => textarea.value};
    } };}
    render() {return {};}
  }};
  const exec = async (path, args) => {
    calls.push({path, args});
    if (path.includes('uname')) return {code:0, stdout:'x86_64'};
    if (path.includes('wget')) return {code:apiAvailable ? 0 : 1, stdout:apiAvailable ? '{"tag_name":"v2.4.0"}' : ''};
    if (reject) throw new Error('RPC failed');
    return {code, stderr:code ? 'disk full' : '', stdout:'test core'};
  };
  const init = new Function('form','fs','poll','rpc','uci','view','alert','confirm','document','_', src);
  const view = init(form, {exec}, {}, {declare:()=>async()=>({})},
    {load:async()=>{},get:()=> 'https://old.invalid/old'}, {extend:x=>x},
    msg=>alerts.push(msg), ()=>true, {getElementById:()=>textarea}, s=>s);
  view.render([null,{}]);
  return {calls, alerts, options, textarea};
}

(async () => {
  const current = fixture({field:'https://new.invalid/core\n\n https://backup.invalid/core '});
  await current.options.download_core.onclick();
  assert.deepEqual(current.calls.at(-1), {path:'/usr/libexec/auth-thu-download', args:['https://new.invalid/core','https://backup.invalid/core']});
  assert.match(current.alerts.at(-1), /successfully/);

  const generated = fixture({field:'https://old.invalid/core'});
  await generated.options.auto_generate_url.onclick();
  await generated.options.download_core.onclick();
  assert(generated.calls.at(-1).args.some(url=>url.includes('/v2.4.0/')));
  assert(!generated.calls.at(-1).args.some(url=>url.includes('old.invalid')));

  const firstUse = fixture({apiAvailable:false});
  await firstUse.options.download_core.onclick();
  assert.match(firstUse.calls.at(-1).args[0], /auth-thu\.linux\.x86_64$/);
  assert(!firstUse.calls.some(call=>call.path.includes('wget')));

  for (const failure of [{code:1},{reject:true}]) {
    const f = fixture({field:'https://new.invalid/core', ...failure});
    await f.options.download_core.onclick();
    assert.match(f.alerts.at(-1), /failed/);
    assert(!f.alerts.some(msg=>msg.includes('successfully')));
  }
  const blank = fixture({field:''});
  await blank.options.download_core.onclick();
  assert.equal(blank.calls.length, 0);
  assert.match(blank.alerts.at(-1), /configure download URLs/);
  console.log('LuCI tests passed: current/generated/default URLs and failure reporting.');
})().catch(e=>{console.error(e);process.exitCode=1;});
