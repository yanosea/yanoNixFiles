import { afterAll, describe, expect, test, mock } from "bun:test"
import { existsSync, mkdtempSync, writeFileSync, rmSync, readFileSync } from "node:fs"
import { join } from "node:path"
import { tmpdir } from "node:os"

const dir = mkdtempSync(join(tmpdir(), "hook-bridge-"))
const entry = join(dir, "fixture.py")
const log = join(dir, "calls.jsonl")
writeFileSync(entry, `import argparse,json,sys\np=argparse.ArgumentParser();p.add_argument('--harness');p.add_argument('--event');a=p.parse_args();d=json.load(sys.stdin)\nwith open(${JSON.stringify(log)},'a') as f:f.write(json.dumps({'harness':a.harness,'event':a.event,'payload':d})+'\\n')\nif a.event in ['execute.before','before_tool_call']:print(json.dumps({'decision':'deny','reason':'policy denied','block':True,'blockReason':'policy denied'}))\nelse:print(json.dumps({'context':'verified context','report':'observed','decision':'allow'}))\n`)
process.env.COMMON_HOOK_ENTRY = entry
const calls = () => readFileSync(log, "utf8").trim().split("\n").map((x) => JSON.parse(x))
afterAll(() => { delete process.env.COMMON_HOOK_ENTRY; rmSync(dir, { recursive: true, force: true }) })

describe("OpenClaw native plugin", () => {
  test("registers typed gates and observes agent_end without sending messages", async () => {
    expect(existsSync(join(import.meta.dir, "../bridges/openclaw/index.ts"))).toBe(true)
    const { default: plugin } = await import("../bridges/openclaw/index.ts")
    const handlers = new Map<string, Function>(); const reports: string[] = []
    plugin.register({ on(name: string, fn: Function) { handlers.set(name, fn) }, logger: { warn: (text: string) => reports.push(text) } } as any)
    const ctx = { sessionId: "s", sessionKey: "k", runId: "r", workspaceDir: dir }
    const injected = await handlers.get("before_prompt_build")!({ messages: [], prompt: "original" }, ctx)
    expect(injected).toEqual({ prependContext: "verified context" })
    expect(await handlers.get("before_tool_call")!({ toolName: "exec", params: { command: "git commit" }, toolCallId: "c" }, ctx)).toEqual({ block: true, blockReason: "policy denied" })
    expect(await handlers.get("after_tool_call")!({ toolName: "exec", params: {}, result: "done" }, ctx)).toBeUndefined()
    expect(await handlers.get("agent_end")!({ messages: [], success: true }, ctx)).toBeUndefined()
    expect(reports).toContain("observed")
    const sent = calls().filter((x) => x.harness === "openclaw")
    expect(sent.map((x) => x.event)).toEqual(["before_prompt_build", "before_tool_call", "after_tool_call", "agent_end"])
    expect(sent[1].payload.workspaceDir).toBe(dir)
    expect(sent[1].payload.params.command).toBe("git commit")
    expect(handlers.has("before_agent_finalize")).toBe(true)
    const withoutId = { sessionKey: "k", runId: "r" }
    expect(await handlers.get("before_tool_call")!({ toolName: "exec", params: {} }, withoutId)).toEqual({ block: true, blockReason: "policy denied" })
    expect(calls().at(-1).payload.sessionId).toBe("s")
    expect(calls().at(-1).payload.workspaceDir).toBe(dir)
  })
  test("missing workspace fails closed for a tool, with no process cwd fallback", async () => {
    const { default: plugin } = await import("../bridges/openclaw/index.ts")
    const handlers = new Map<string, Function>()
    plugin.register({ on(name: string, fn: Function) { handlers.set(name, fn) }, logger: { warn() {} } } as any)
    const result = await handlers.get("before_tool_call")!({ toolName: "exec", params: {} }, { sessionId: "unknown" })
    expect(result.block).toBe(true)
    expect(result.blockReason).toContain("workspace")
  })
  test("appends the shared planning rules only when the file path is set", async () => {
    const { default: plugin } = await import("../bridges/openclaw/index.ts")
    const handlers = new Map<string, Function>()
    plugin.register({ on(name: string, fn: Function) { handlers.set(name, fn) }, logger: { warn() {} } } as any)
    const build = () => handlers.get("before_prompt_build")!({ messages: [], prompt: "p" }, { sessionId: "rules", runId: "r", workspaceDir: dir })
    expect(await build()).toEqual({ prependContext: "verified context" })
    const rules = join(dir, "planning-and-delegation.md")
    writeFileSync(rules, "# Planning\n\nUse the agents.\n")
    process.env.OPENCLAW_PLANNING_RULES_FILE = rules
    try {
      expect(await build()).toEqual({ prependContext: "verified context", appendSystemContext: "# Planning\n\nUse the agents." })
      process.env.OPENCLAW_PLANNING_RULES_FILE = join(dir, "gone.md")
      expect(await build()).toEqual({ prependContext: "verified context" })
    } finally { delete process.env.OPENCLAW_PLANNING_RULES_FILE }
  })
})

test("OpenClaw runs the hook with the python in COMMON_HOOK_PYTHON_DIR", async () => {
  const { default: plugin } = await import("../bridges/openclaw/index.ts")
  const handlers = new Map<string, Function>()
  plugin.register({ on(name: string, fn: Function) { handlers.set(name, fn) }, logger: { warn() {} } } as any)
  const bin = mkdtempSync(join(dir, "bin-"))
  writeFileSync(join(bin, "python3"), "#!/bin/sh\ncat >/dev/null\necho '{\"block\":true,\"blockReason\":\"pinned python\"}'\n", { mode: 0o755 })
  process.env.COMMON_HOOK_PYTHON_DIR = bin
  try {
    expect(await handlers.get("before_tool_call")!({ toolName: "exec", params: {} }, { sessionId: "py", workspaceDir: dir }))
      .toEqual({ block: true, blockReason: "pinned python" })
  } finally { delete process.env.COMMON_HOOK_PYTHON_DIR }
})

test("OpenClaw revises only external user development loops and never agent_end", async () => {
  const { default: plugin } = await import("../bridges/openclaw/index.ts")
  const handlers = new Map<string, Function>()
  plugin.register({ on(name: string, fn: Function) { handlers.set(name, fn) }, logger: { warn() {} } } as any)
  const continueEntry = join(dir, "claw-continue.py")
  writeFileSync(continueEntry, "import json,sys\njson.load(sys.stdin)\nprint(json.dumps({'action':'revise','reason':'next','loop':{'state':'running'}}))\n")
  process.env.COMMON_HOOK_ENTRY = continueEntry
  try {
    for (const ctx of [
      { trigger: "cron", inputProvenance: { kind: "external_user" } },
      { trigger: "heartbeat", inputProvenance: { kind: "external_user" } },
      { trigger: "user" }, { trigger: "user", inputProvenance: { kind: "internal_system" } },
      {},
    ]) {
      expect(await handlers.get("before_agent_finalize")!({}, { sessionId: "guarded", workspaceDir: dir, ...ctx })).toBeUndefined()
    }
    expect(await handlers.get("before_agent_finalize")!({}, {
      sessionId: "dev", workspaceDir: dir, trigger: "user", inputProvenance: { kind: "external_user" },
    })).toEqual({ action: "revise", reason: "next" })
    expect(await handlers.get("agent_end")!({}, { sessionId: "dev", workspaceDir: dir })).toBeUndefined()
  } finally { process.env.COMMON_HOOK_ENTRY = entry }
})

// The fixture checks the registered Effect callback's native failure channel.
// Real OpenCode loading is verified separately; this does not simulate a model.
const run = async (value: any): Promise<any> => typeof value === "function" ? value() : value?.run ? value.run() : value
const fx = (task: Function): any => ({ run: task, *[Symbol.iterator]() { return yield task }, pipe: (...fs: Function[]) => fs.reduce((x, f) => f(x), fx(task)) })
const Effect = {
  gen: (f: Function) => fx(async () => { const g = f(); let item = g.next(); while (!item.done) { try { item = g.next(await run(item.value)) } catch (error) { item = g.throw(error) } } return item.value }),
  fn: (f: Function) => (...args: any[]) => Effect.gen(() => f(...args)),
  promise: (f: Function) => fx(f),
  tryPromise: ({ try: f, catch: recover }: any) => fx(async () => { try { return await f() } catch (e) { throw recover(e) } }),
  sync: (f: Function) => fx(f),
  flatMap: (f: Function) => (x: any) => fx(async () => run(f(await run(x)))),
  fail: (e: any) => fx(() => { throw e }),
  forkScoped: (_options: any) => (x: any) => fx(() => run(x)),
  catch: (f: Function) => (x: any) => fx(async () => { try { return await run(x) } catch (e) { return run(f(e)) } }),
}
// A direct effect fixture avoids installing a second copy into the real profile.
let eventCallback: Function
let durableSeq = 0
const nativeEvent = (event: any) => {
  const seq = event.durable?.seq ?? ++durableSeq
  return eventCallback({ id: event.id || `evt_fixture_${seq}`, durable: { aggregateID: event.data.sessionID, seq, version: 1 }, ...event })
}
mock.module("effect", () => ({ Effect, Stream: { runForEach: (callback: Function) => (_stream: any) => { eventCallback = callback; return fx(() => undefined) } } }))
mock.module("@opencode/plugin/effect", () => ({ Plugin: { define: (value: any) => value } }))
// Only the package names exposed by OpenCode's runtime loader are available.
mock.module("@opencode/plugin/promise/tool", () => ({ Error: class extends Error { _tag = "Tool.Error"; constructor(input: any) { super(input.message) } } }))

describe("OpenCode V2 native Effect plugin", () => {
  test("uses Tool.Error denial before execution and preserves post result", async () => {
    expect(existsSync(join(import.meta.dir, "../bridges/opencode.ts"))).toBe(true)
    const { default: plugin } = await import("../bridges/opencode.ts")
    expect(plugin.id).toBe("common-hooks")
    const handlers = new Map<string, Function>()
    const register = (name: string, fn: Function) => fx(() => { handlers.set(name, fn) })
    const ctx = {
      session: { get: () => fx(() => ({ location: { directory: dir } })), hook: register },
      tool: { hook: register }, event: { subscribe: () => ({pipe: (...fs:Function[])=>fs.reduce((x,f)=>f(x),[] as any)}) },
    }
    await run(plugin.effect(ctx as any))
    const event = { sessionID: "s", messageID: "m", id: "c", tool: "bash", input: { command: "git commit" } }
    try { await run(handlers.get("execute.before")!(event)); throw new Error("denial missing") }
    catch (error: any) { expect(error._tag).toBe("Tool.Error"); expect(error.message).toBe("policy denied") }
    const post = { ...event, status: "completed", result: { content: "tool output", metadata: {} } }
    await run(handlers.get("execute.after")!(post))
    expect(post.result.content).toEqual([{ type: "text", text: "tool output" }, { type: "text", text: "verified context" }])
    const model = { sessionID: "s", system: [] }
    await run(handlers.get("context")!(model))
    expect(model.system).toEqual([])
    const next = { sessionID: "s", system: [] }
    await run(handlers.get("context")!(next))
    expect(next.system).toEqual([{ type: "text", text: "verified context" }])
    const sent = calls().filter((x) => x.harness === "opencode")
    expect(sent[0].payload.cwd).toBe(dir)
    expect(sent[0].payload.input.command).toBe("git commit")
  })
  test("factory uses an explicit project entry and plugin id", async () => {
    const { createPlugin } = await import("../bridges/opencode.ts")
    expect(typeof createPlugin).toBe("function")
    const projectEntry = join(dir, "project.py")
    writeFileSync(projectEntry, "import json,sys\njson.load(sys.stdin)\nprint(json.dumps({'context':'project context','decision':'allow'}))\n")
    const plugin = createPlugin({ entry: projectEntry, id: "ai-loop" })
    expect(plugin.id).toBe("ai-loop")
    const handlers = new Map<string, Function>()
    const register = (name: string, fn: Function) => fx(() => { handlers.set(name, fn) })
    await run(plugin.effect({ session: { get: () => fx(() => ({ location: { directory: dir } })), hook: register }, tool: { hook: register }, event: { subscribe: () => ({pipe: (...fs:Function[])=>fs.reduce((x,f)=>f(x),[] as any)}) } } as any))
    const model = { sessionID: "project-session", system: [] }
    await run(handlers.get("context")!(model))
    expect(model.system).toEqual([])
    const next = { sessionID: "project-session", system: [] }
    await run(handlers.get("context")!(next))
    expect(next.system).toEqual([{ type: "text", text: "project context" }])
  })
  test("factory bounds its explicit timeout and ends delayed project calls", async () => {
    const { createPlugin } = await import("../bridges/opencode.ts")
    for (const timeoutMs of [0, -1, 600_001, NaN, Infinity]) {
      expect(() => createPlugin({ timeoutMs })).toThrow("timeoutMs")
    }
    const delayed = join(dir, "delayed.py")
    writeFileSync(delayed, "import time\ntime.sleep(5)\nprint('{}')\n")
    const plugin = createPlugin({ id: "bounded-project", entry: delayed, timeoutMs: 50 })
    const handlers = new Map<string, Function>()
    const register = (name: string, fn: Function) => fx(() => { handlers.set(name, fn) })
    await run(plugin.effect({ session: { get: () => fx(() => ({ location: { directory: dir } })), hook: register }, tool: { hook: register }, event: { subscribe: () => ({pipe: (...fs:Function[])=>fs.reduce((x,f)=>f(x),[] as any)}) } } as any))
    const started = Date.now()
    try { await run(handlers.get("execute.before")!({ sessionID: "delayed", tool: "bash", input: {} })); throw new Error("timeout denial missing") }
    catch (error: any) { expect(error._tag).toBe("Tool.Error"); expect(error.message).toContain("could not evaluate") }
    expect(Date.now() - started).toBeLessThan(2000)
  })

})

test("OpenCode continues only positive completion and durable claim once", async () => {
  const { createPlugin } = await import("../bridges/opencode.ts")
  const protocol = join(dir, "continue.py"), protocolLog = join(dir, "protocol.jsonl")
  writeFileSync(protocol, `import argparse,json,sys
p=argparse.ArgumentParser();p.add_argument('--harness');p.add_argument('--event');a=p.parse_args();d=json.load(sys.stdin)
with open(${JSON.stringify(protocolLog)},'a') as f:f.write(json.dumps({'event':a.event,'payload':d})+'\\n')
if a.event == 'session.execution.succeeded': print(json.dumps({'action':'continue','context':'next task','loop':{'id':'loop','state':'running','request_id':'req','owner_epoch':1}}))
elif a.event == 'LoopValidateDelivery':print(json.dumps({'valid':True}))
elif a.event == 'LoopClaimDelivery':
 rows=[json.loads(x) for x in open(${JSON.stringify(protocolLog)})]
 print(json.dumps({'claimed':sum(r['event']=='LoopClaimDelivery' for r in rows)==1}))
else: print('{}')
`)
  const handlers = new Map<string, Function>(), prompts: any[] = []
  const register = (name: string, fn: Function) => fx(() => { handlers.set(name, fn) })
  const ctx = { session: { get: () => fx(() => ({ location: { directory: dir } })), hook: register,
    prompt: (input: any) => fx(async () => { await run(handlers.get("prompt")!({sessionID: input.sessionID, messageID:"own", metadata: input.metadata, prompt:{text:input.text}})); prompts.push(input); return {} }) },
    tool: { hook: register }, event: { subscribe: () => ({pipe: (...fs:Function[])=>fs.reduce((x,f)=>f(x),[] as any)}) } }
  await run(createPlugin({ entry: protocol }).effect(ctx as any))
  await run(nativeEvent({type:"session.status", data:{sessionID:"s",status:{type:"idle"}}}))
  expect(prompts).toHaveLength(0)
  await run(nativeEvent({type:"session.execution.failed", data:{sessionID:"s",error:{message:"failed"}}}))
  expect(prompts).toHaveLength(0)
  await run(nativeEvent({type:"session.step.ended", data:{sessionID:"s",finish:"stop"}}))
  await run(nativeEvent({type:"session.execution.succeeded", data:{sessionID:"s"}}))
  expect(prompts).toHaveLength(1)
  expect(prompts[0].sessionID).toBe("s")
  expect(prompts[0].text).toBe("next task")
  expect(prompts[0].metadata.commonLoopRequest).toBe("req")
  await run(nativeEvent({type:"session.execution.succeeded", data:{sessionID:"s"}}))
  expect(prompts).toHaveLength(1)
  const rows = readFileSync(protocolLog,"utf8").trim().split("\n").map(x=>JSON.parse(x))
  expect(rows.some(x=>x.event==="LoopDeliveryAccepted")).toBe(true)
})

test("OpenCode unknown delivery is recorded without retry, new user aborts pending continuation", async () => {
  const { createPlugin } = await import("../bridges/opencode.ts")
  const protocol = join(dir, "uncertain.py"), protocolLog = join(dir, "uncertain.jsonl")
  writeFileSync(protocol, `import argparse,json,sys,time
p=argparse.ArgumentParser();p.add_argument('--harness');p.add_argument('--event');a=p.parse_args();d=json.load(sys.stdin)
with open(${JSON.stringify(protocolLog)},'a') as f:f.write(json.dumps({'event':a.event,'payload':d})+'\\n')
if a.event == 'session.execution.succeeded':
 time.sleep(.08)
 print(json.dumps({'action':'continue','context':'next','loop':{'id':'l','state':'running','request_id':'r'}}))
elif a.event == 'LoopValidateDelivery':print(json.dumps({'valid':True}))
elif a.event == 'LoopClaimDelivery':print(json.dumps({'claimed':True}))
else:print('{}')
`)
  const handlers = new Map<string, Function>(); let promptCalls = 0
  const register = (name: string, fn: Function) => fx(() => { handlers.set(name, fn) })
  const ctx = { session: { get: () => fx(() => ({ location: { directory: dir } })), hook: register,
    prompt: () => fx(() => { promptCalls++; throw new Error("transport uncertain") }) }, tool:{hook:register}, event:{subscribe:()=>({pipe:(...fs:Function[])=>fs.reduce((x,f)=>f(x),[] as any)})} }
  await run(createPlugin({entry:protocol}).effect(ctx as any))
  await run(nativeEvent({type:"session.step.ended",data:{sessionID:"race",finish:"stop"}}))
  const complete = run(nativeEvent({type:"session.execution.succeeded",data:{sessionID:"race"}}))
  await new Promise(resolve=>setTimeout(resolve,20))
  await run(handlers.get("prompt")!({sessionID:"race",messageID:"human",prompt:{text:"stop"}}))
  await complete
  expect(promptCalls).toBe(0)
  await run(nativeEvent({type:"session.step.ended",data:{sessionID:"uncertain",finish:"stop"}}))
  await run(nativeEvent({type:"session.execution.succeeded",data:{sessionID:"uncertain"}}))
  expect(promptCalls).toBe(1)
  const rows = readFileSync(protocolLog,"utf8").trim().split("\n").map(x=>JSON.parse(x))
  expect(rows.some(x=>x.event==="LoopDeliveryUnknown")).toBe(true)
  expect(rows.some(x=>x.event==="LoopDeliveryAborted")).toBe(true)
})

test("OpenCode respects native maximum steps, length, and unknown completion", async () => {
  const {createPlugin} = await import("../bridges/opencode.ts")
  const handlers = new Map<string,Function>(); let prompts = 0
  const register = (name:string,fn:Function)=>fx(()=>{handlers.set(name,fn)})
  const ctx = {session:{get:()=>fx(()=>({location:{directory:dir}})),hook:register,prompt:()=>fx(()=>{prompts++})},tool:{hook:register},event:{subscribe:()=>({pipe:(...fs:Function[])=>fs.reduce((x,f)=>f(x),[] as any)})}}
  await run(createPlugin().effect(ctx as any))
  for (const finish of [undefined,"length","content-filter"]) {
    const id = "finish-"+finish
    if (finish) await run(nativeEvent({type:"session.step.ended",data:{sessionID:id,finish}}))
    await run(nativeEvent({type:"session.execution.succeeded",data:{sessionID:id}}))
  }
  const model = {sessionID:"limited",system:[],messages:[{role:"assistant",content:[{type:"text",text:"CRITICAL - MAXIMUM STEPS REACHED\n\nThe maximum number of steps allowed for this task has been reached. Tools are disabled until next user input."}]}]}
  await run(handlers.get("context")!(model))
  await run(nativeEvent({type:"session.step.ended",data:{sessionID:"limited",finish:"stop"}}))
  await run(nativeEvent({type:"session.execution.succeeded",data:{sessionID:"limited"}}))
  expect(prompts).toBe(0)
  const sent = calls().filter(x=>x.harness==="opencode" && x.event==="session.execution.succeeded")
  expect(sent.slice(-4).every(x=>x.payload.stop_reason!=="natural")).toBe(true)
})

test("OpenCode shared global and project admission accept a single durable continuation", async () => {
  const {createPlugin} = await import("../bridges/opencode.ts")
  const protocol = join(dir,"two-plugins.py"), ledger=join(dir,"two-ledger.json")
  writeFileSync(protocol, `import argparse,json,sys,os
p=argparse.ArgumentParser();p.add_argument('--harness');p.add_argument('--event');a=p.parse_args();d=json.load(sys.stdin)
f=${JSON.stringify(ledger)}
if a.event=='session.execution.succeeded':print(json.dumps({'action':'continue','context':'next','loop':{'id':'l','state':'running','request_id':'r','owner_epoch':1}}))
elif a.event=='LoopClaimDelivery':
 exists=os.path.exists(f)
 open(f,'w').write('claimed')
 print(json.dumps({'claimed':not exists}))
elif a.event=='LoopValidateDelivery':print(json.dumps({'valid':os.path.exists(f) and d.get('request_id')=='r'}))
else:print('{}')
`)
  const admissions:Function[] = [], callbacks:Function[]=[]; let sends=0
  const register=(name:string,fn:Function)=>fx(()=>{if(name==="prompt")admissions.push(fn)})
  const ctx={session:{get:()=>fx(()=>({location:{directory:dir}})),hook:register,prompt:(input:any)=>fx(async()=>{for(const admission of admissions)await run(admission({sessionID:input.sessionID,messageID:"synthetic",prompt:{text:input.text},metadata:input.metadata}));sends++;return {}})},tool:{hook:register},event:{subscribe:()=>({pipe:(...fs:Function[])=>fs.reduce((x,f)=>f(x),[] as any)})}}
  for(const id of ["global","project"]){await run(createPlugin({id,entry:protocol}).effect(ctx as any));callbacks.push(eventCallback)}
  for(const callback of callbacks)await run(callback({id:"evt_step",durable:{seq:10},type:"session.step.ended",data:{sessionID:"s",finish:"stop"}}))
  for(const callback of callbacks)await run(callback({id:"evt_success",durable:{seq:11},type:"session.execution.succeeded",data:{sessionID:"s"}}))
  expect(sends).toBe(1)
})

test("OpenCode rejects repeated prior completion and prior step after a new execution starts", async () => {
  const {createPlugin}=await import("../bridges/opencode.ts")
  let prompts=0
  const ctx={session:{get:()=>fx(()=>({location:{directory:dir}})),hook:()=>fx(()=>{}),prompt:()=>fx(()=>{prompts++;return{}})},tool:{hook:()=>fx(()=>{})},event:{subscribe:()=>({pipe:(...fs:Function[])=>fs.reduce((x,f)=>f(x),[] as any)})}}
  await run(createPlugin().effect(ctx as any))
  await run(nativeEvent({id:"evt_started_new",durable:{seq:200},type:"session.execution.started",data:{sessionID:"replay"}}))
  const before=calls().length
  await run(nativeEvent({id:"evt_old_step",durable:{seq:100},type:"session.step.ended",data:{sessionID:"replay",finish:"stop"}}))
  await run(nativeEvent({id:"evt_old_success",durable:{seq:101},type:"session.execution.succeeded",data:{sessionID:"replay"}}))
  expect(prompts).toBe(0)
  expect(calls()).toHaveLength(before)
})


test("OpenCode delivers the session context one dispatch late and hands the latest stop result to the next one once", async () => {
  const {createPlugin}=await import("../bridges/opencode.ts")
  const protocol=join(dir,"stop-context.py"), outcome=join(dir,"stop-outcome.json")
  writeFileSync(protocol, `import argparse,json,sys
p=argparse.ArgumentParser();p.add_argument('--harness');p.add_argument('--event');a=p.parse_args();json.load(sys.stdin)
if a.event=='SessionStart':print(json.dumps({'action':'allow','context':'handover'}))
elif a.event in ('session.idle','session.execution.succeeded'):print(open(${JSON.stringify(outcome)}).read())
else:print(json.dumps({'action':'allow','context':''}))
`)
  const handlers=new Map<string,Function>()
  const register=(name:string,fn:Function)=>fx(()=>{handlers.set(name,fn)})
  const ctx={session:{get:()=>fx(()=>({location:{directory:dir}})),hook:register,prompt:()=>fx(()=>({}))},tool:{hook:register},event:{subscribe:()=>({pipe:(...fs:Function[])=>fs.reduce((x,f)=>f(x),[] as any)})}}
  await run(createPlugin({id:"ai-loop",entry:protocol}).effect(ctx as any))
  const dispatch=async()=>{const model={sessionID:"stops",system:[] as any[]};await run(handlers.get("context")!(model));return model.system.map((x:any)=>x.text)}
  expect(await dispatch()).toEqual([])
  expect(await dispatch()).toEqual(["handover"])
  writeFileSync(outcome, JSON.stringify({action:"notify",context:"check-docs.sh: FAIL\nbroken link"}))
  await run(nativeEvent({type:"session.status",data:{sessionID:"stops",status:{type:"idle"}}}))
  expect(await dispatch()).toEqual(["handover","Post-work checks after the previous turn (ai-loop) reported:\ncheck-docs.sh: FAIL\nbroken link"])
  expect(await dispatch()).toEqual(["handover"])
  writeFileSync(outcome, JSON.stringify({action:"allow",context:"check-docs.sh: PASS\naistudio check all: PASS\nsummary"}))
  await run(nativeEvent({type:"session.step.ended",data:{sessionID:"stops",finish:"stop"}}))
  await run(nativeEvent({type:"session.execution.succeeded",data:{sessionID:"stops"}}))
  expect(await dispatch()).toEqual(["handover","Post-work checks after the previous turn (ai-loop): all PASS (check-docs.sh, aistudio check all)"])
  expect(await dispatch()).toEqual(["handover"])
  writeFileSync(outcome, JSON.stringify({action:"allow",context:""}))
  await run(nativeEvent({type:"session.status",data:{sessionID:"stops",status:{type:"idle"}}}))
  expect(await dispatch()).toEqual(["handover"])
})
