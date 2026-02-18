#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const repoRoot = process.cwd();
const targets = [
  path.join(repoRoot, ".test"),
  path.join(repoRoot, "good-writing"),
  path.join(repoRoot, "de-AI-writing"),
];

function walk(dir, out) {
  if (!fs.existsSync(dir)) return;
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    const stat = fs.statSync(full);
    if (stat.isDirectory()) {
      walk(full, out);
      continue;
    }
    if (full.toLowerCase().endsWith(".md")) out.push(full);
  }
}

function stripNonBodyForChecks(text) {
  const lines = text.split(/\r?\n/);
  const cleaned = [];
  let inFence = false;
  let inFrontmatter = false;
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (index === 0 && line.trim() === "---") {
      inFrontmatter = true;
      continue;
    }
    if (inFrontmatter) {
      if (line.trim() === "---") inFrontmatter = false;
      continue;
    }
    if (line.trim().startsWith("```")) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (line.trim().startsWith(">")) continue;
    cleaned.push(line);
  }
  return cleaned.join("\n");
}

function countFirstPerson(text) {
  const clean = stripNonBodyForChecks(text);
  const matches = clean.match(/我们|我/g);
  return matches ? matches.length : 0;
}

function hasArShi(text) {
  const clean = stripNonBodyForChecks(text);
  return /而是/.test(clean);
}

function markdownSignals(text) {
  const signals = [];
  const headingCount = (text.match(/^##\s+/gm) || []).length;
  if (headingCount > 3) signals.push(`heading(${headingCount})`);
  if (/^\s*[-*+]\s+/m.test(text) || /^\s*\d+\.\s+/m.test(text)) signals.push("list");
  if (/\*\*[^*]+\*\*/.test(text)) signals.push("bold");
  return signals;
}

const files = [];
for (const dir of targets) walk(dir, files);

const failures = [];

for (const file of files) {
  const rel = path.relative(repoRoot, file).replace(/\\/g, "/");
  const text = fs.readFileSync(file, "utf8");

  if (rel.startsWith(".test/") && hasArShi(text)) {
    failures.push(`${rel}: contains "而是" in body`);
  }

  if (rel.startsWith(".test/")) {
    const signals = markdownSignals(text);
    if (signals.length > 0) {
      failures.push(`${rel}: markdown signals -> ${signals.join(", ")}`);
    }
  }

  if (rel.startsWith(".test/") && /de-ai-writing/i.test(rel)) {
    const fp = countFirstPerson(text);
    if (fp > 2) failures.push(`${rel}: first-person count ${fp} > 2`);
  }
}

if (failures.length === 0) {
  console.log("style_audit: OK");
  process.exit(0);
}

console.log("style_audit: FAIL");
for (const item of failures) console.log(`- ${item}`);
process.exit(1);
