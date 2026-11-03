#!/usr/bin/env node
/*
 * unit - runs the ABAP Unit tests of this repository without an SAP system,
 * on the transpiled Node runtime abap2UI5 uses for its own suite (SQLite
 * behind the database statements, so RISK LEVEL DANGEROUS classes run too).
 *
 * What it does, the same in CI (abap-unit.yaml) and on a laptop:
 *
 *   1. a checkout of every repository in CONFIG.repos under UNIT_DIR
 *      (default .unit/, git-ignored) - cloned on the first run, refreshed to
 *      the tip of its ref on every later one
 *   2. npm ci in the abap2UI5 checkout (skipped while its lock is unchanged)
 *   3. CONFIG.packages copied into its src/ as extra packages
 *   4. npm run downport && npm run auto_transpile there
 *   5. the generated tests of the classes starting with CONFIG.prefix - all
 *      risk levels, nothing else of abap2UI5's suite - each one reported,
 *      exit code 1 on any failure or when no test ran at all
 *
 *   npm run unit
 *   UNIT_FILTER=ltcl_rec npm run unit
 *
 * Environment:
 *   UNIT_DIR        the work folder (default .unit)
 *   UNIT_FILTER     run only the tests whose "OBJECT: class->method" contains it
 *   UNIT_NO_FETCH=1 use the checkouts under UNIT_DIR as they are - CI sets
 *                   it, actions/checkout has put them there already
 *
 * Never commit the work folder. A green transpiled run is not a substitute
 * for a run on a system (abap2UI5's abap-check skill lists what the
 * transpiler cannot see).
 */
import { execFileSync, spawnSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const WORK = path.resolve(ROOT, process.env.UNIT_DIR || ".unit");

const CONFIG = {
  // the test classes of this repository
  prefix: "Z2UI5_CL_SQL",
  // checkouts under WORK; the first one is the abap2UI5 tree everything is
  // built in, the others are what this repository builds on
  repos: [
    { name: "abap2UI5", url: "https://github.com/abap2UI5/abap2UI5", ref: "main" },
    { name: "abap2UI5-ext", url: "https://github.com/abap2UI5/abap2UI5-ext", ref: "main" },
    { name: "layout-management", url: "https://github.com/abap2UI5-addons/layout-management", ref: "main" },
    { name: "popups", url: "https://github.com/abap2UI5-addons/popups", ref: "main" },
    { name: "custom-controls", url: "https://github.com/abap2UI5-addons/custom-controls", ref: "main" },
  ],
  // copied into <abap2UI5>/src/<into>/: entries relative to <from>/src
  // src/native is left out: its ADT data-preview classes are on-premise
  // only and do not pass the downport of the abap2UI5 tree
  packages: [
    { into: "zz_abap2ui5_ext", from: path.join(WORK, "abap2UI5-ext"), entries: ["."] },
    { into: "zz_layout_management", from: path.join(WORK, "layout-management"), entries: ["."] },
    { into: "zz_popups", from: path.join(WORK, "popups"), entries: ["."] },
    { into: "zz_custom_controls", from: path.join(WORK, "custom-controls"), entries: ["."] },
    { into: "zz_sql_console", from: ROOT, entries: ["package.devc.xml",  "abap"] },
  ],
};

const NPM = process.platform === "win32" ? "npm.cmd" : "npm";

function fail(message) {
  console.error(`::error::unit: ${message}`);
  process.exit(1);
}

function git(args, cwd) {
  return execFileSync("git", args, { cwd, stdio: ["ignore", "pipe", "inherit"] }).toString().trim();
}

function step(title, cmd, args, cwd) {
  console.log(`\n== ${title}`);
  const r = spawnSync(cmd, args, { cwd, stdio: "inherit", shell: process.platform === "win32" });
  if (r.status !== 0) fail(`${title} failed (exit ${r.status ?? r.signal})`);
}

function checkout(repo) {
  const dir = path.join(WORK, repo.name);
  if (process.env.UNIT_NO_FETCH === "1") {
    if (!fs.existsSync(path.join(dir, ".git"))) fail(`UNIT_NO_FETCH is set, but ${dir} is no checkout`);
  } else {
    if (!fs.existsSync(path.join(dir, ".git"))) {
      fs.mkdirSync(dir, { recursive: true });
      git(["init", "--quiet"], dir);
      git(["remote", "add", "origin", repo.url], dir);
    } else {
      git(["remote", "set-url", "origin", repo.url], dir);
    }
    git(["fetch", "--quiet", "--depth", "1", "origin", repo.ref], dir);
    git(["checkout", "--quiet", "--force", "--detach", "FETCH_HEAD"], dir);
  }
  console.log(`${repo.name} ${repo.ref} @ ${git(["rev-parse", "HEAD"], dir)}`);
  return dir;
}

// 1. checkouts
fs.mkdirSync(WORK, { recursive: true });
const dirs = Object.fromEntries(CONFIG.repos.map((r) => [r.name, checkout(r)]));
const A2U = dirs[CONFIG.repos[0].name];

// 2. dependencies of the abap2UI5 tree
const lock = path.join(A2U, "package-lock.json");
const stamp = path.join(A2U, "node_modules", ".unit-lock-sha256");
const lockHash = crypto.createHash("sha256").update(fs.readFileSync(lock)).digest("hex");
if (!fs.existsSync(stamp) || fs.readFileSync(stamp, "utf8") !== lockHash) {
  step("npm ci (abap2UI5)", NPM, ["ci", "--no-audit", "--no-fund"], A2U);
  fs.writeFileSync(stamp, lockHash);
}

// 3. the packages under test, on a clean tree
for (const p of [path.join(A2U, "node", "downport"), path.join(A2U, "node", "output")]) {
  fs.rmSync(p, { recursive: true, force: true });
}
for (const pkg of CONFIG.packages) {
  const target = path.join(A2U, "src", pkg.into);
  fs.rmSync(target, { recursive: true, force: true });
  fs.mkdirSync(target, { recursive: true });
  for (const entry of pkg.entries) {
    const source = path.join(pkg.from, "src", entry);
    if (!fs.existsSync(source)) fail(`${source} does not exist`);
    fs.cpSync(source, entry === "." ? target : path.join(target, entry), { recursive: true });
  }
  console.log(`src/${pkg.into} <- ${pkg.from === ROOT ? "this repository" : path.relative(ROOT, pkg.from)}: src/{${pkg.entries.join(",")}}`);
}

// 4. downport and transpile
step("npm run downport", NPM, ["run", "downport"], A2U);
step("npm run auto_transpile", NPM, ["run", "auto_transpile"], A2U);

// 5. the generated tests of this repository's classes
const output = path.join(A2U, "node", "output");
const index = fs.readFileSync(path.join(output, "index.mjs"), "utf8");
const cut = index.indexOf("async function run");
if (cut < 0) fail("node/output/index.mjs has no 'async function run' - the transpiler's runner changed");

const runner = `
const PREFIX = ${JSON.stringify(CONFIG.prefix)};
const FILTER = ${JSON.stringify(process.env.UNIT_FILTER || "")};

function describe(e) {
  const str = (v) => { try { return v && v.get ? String(v.get()) : ""; } catch { return ""; } };
  const parts = [e?.constructor?.name || String(e)];
  if (e?.msg && str(e.msg)) parts.push(str(e.msg));
  if (e?.expected && str(e.expected)) parts.push("expected: " + str(e.expected).slice(0, 2000));
  if (e?.actual && str(e.actual)) parts.push("actual: " + str(e.actual).slice(0, 2000));
  if (parts.length === 1 && e?.message) parts.push(e.message);
  return parts.join("\\n    ");
}

async function run() {
  const tally = { passed: 0, failed: 0, skipped: 0 };
  const risks = {};
  for (const st of getData()) {
    if (!st.objectName.startsWith(PREFIX)) continue;
    const methods = st.methods.filter((m) => !FILTER || (st.objectName + ": " + st.localClass + "->" + m.name).includes(FILTER));
    if (methods.length === 0) continue;
    const imported = await import(st.filename);
    const localClass = imported[st.localClass];
    try {
      if (localClass.class_setup) await localClass.class_setup();
    } catch (e) {
      for (const m of methods) console.log("FAIL " + st.objectName + ": " + st.localClass + "->" + m.name + " (class_setup)");
      console.log("    " + describe(e));
      tally.failed += methods.length;
      continue;
    }
    for (const m of methods) {
      const name = st.objectName + ": " + st.localClass + "->" + m.name;
      if (m.skip) {
        console.log("SKIP " + name + " (abap_transpile.json)");
        tally.skipped++;
        continue;
      }
      let error;
      let test;
      try {
        test = await (new localClass()).constructor_();
        if (test.setup) await test.setup();
        if (test.FRIENDS_ACCESS_INSTANCE.setup) await test.FRIENDS_ACCESS_INSTANCE.setup();
        if (test.FRIENDS_ACCESS_INSTANCE.SUPER && test.FRIENDS_ACCESS_INSTANCE.SUPER.setup) await test.FRIENDS_ACCESS_INSTANCE.SUPER.setup();
        await test.FRIENDS_ACCESS_INSTANCE[m.name]();
      } catch (e) {
        error = e;
      }
      try {
        if (test && test.teardown) await test.teardown();
        if (test && test.FRIENDS_ACCESS_INSTANCE.teardown) await test.FRIENDS_ACCESS_INSTANCE.teardown();
        if (test && test.FRIENDS_ACCESS_INSTANCE.SUPER && test.FRIENDS_ACCESS_INSTANCE.SUPER.teardown) await test.FRIENDS_ACCESS_INSTANCE.SUPER.teardown();
      } catch (e) {
        error = error || e;
      }
      if (error) {
        console.log("FAIL " + name + " [" + st.riskLevel + "]");
        console.log("    " + describe(error));
        if (process.env.UNIT_STACK) console.log(error?.stack);
        tally.failed++;
      } else {
        console.log("PASS " + name + " [" + st.riskLevel + "]");
        tally.passed++;
        risks[st.riskLevel] = (risks[st.riskLevel] || 0) + 1;
      }
    }
    try {
      if (localClass.class_teardown) await localClass.class_teardown();
    } catch (e) {
      console.log("FAIL " + st.objectName + ": " + st.localClass + " (class_teardown)");
      console.log("    " + describe(e));
      tally.failed++;
    }
  }
  const byRisk = Object.entries(risks).map(([k, v]) => k + " " + v).join(", ");
  console.log("\\n" + PREFIX + "*: " + tally.passed + " passed, " + tally.failed + " failed, " + tally.skipped + " skipped" + (byRisk ? " (passed by risk level: " + byRisk + ")" : ""));
  if (tally.passed + tally.failed === 0) {
    console.log("::error::no test of " + PREFIX + "* ran" + (FILTER ? " for UNIT_FILTER=" + FILTER : ""));
    return 1;
  }
  return tally.failed ? 1 : 0;
}

run().then((code) => process.exit(code)).catch((err) => {
  console.log(err);
  process.exit(1);
});
`;

const file = path.join(output, "unit-addon.mjs");
fs.writeFileSync(file, index.slice(0, cut) + runner);
console.log(`\n== ABAP Unit: ${CONFIG.prefix}*${process.env.UNIT_FILTER ? ` matching "${process.env.UNIT_FILTER}"` : ""}`);
const r = spawnSync(process.execPath, [file], { cwd: output, stdio: "inherit" });
process.exit(r.status ?? 1);
